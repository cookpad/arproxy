module Arproxy
  class ConnectionAdapterPatch
    attr_reader :adapter_class

    def initialize(adapter_class)
      @adapter_class = adapter_class
      @applied_patches = Set.new
    end

    def enable!
      case adapter_class::ADAPTER_NAME
      when 'Mysql2', 'Trilogy'
        if ActiveRecord.version >= '7.0'
          apply_patch :raw_execute
        else
          apply_patch :execute
        end
      when 'PostgreSQL'
        if ActiveRecord.version >= '7.1'
          apply_patch :raw_execute
        else
          apply_patch :execute
        end
        apply_patch_binds :exec_no_cache
        apply_patch_binds :exec_cache
      when 'SQLServer', 'SQLite'
        if ActiveRecord.version >= '7.1'
          apply_patch :raw_execute
          apply_patch_binds :internal_exec_query
        else
          apply_patch :execute
          apply_patch_binds :exec_query
        end
      else
        raise Arproxy::Error, "Unexpected connection adapter: #{adapter_class&.name}"
      end
      ::Arproxy.logger.debug("Arproxy: Enabled (#{adapter_class::ADAPTER_NAME})")
    end

    def disable!
      @applied_patches.dup.each do |target_method|
        adapter_class.class_eval do
          if respond_to?(:"#{target_method}_with_arproxy")
            alias_method target_method, :"#{target_method}_without_arproxy"
            remove_method :"#{target_method}_with_arproxy"
          end
        end
        @applied_patches.delete(target_method)
      end
      ::Arproxy.logger.debug("Arproxy: Disabled (#{adapter_class::ADAPTER_NAME})")
    end

    private
      def apply_patch(target_method)
        return if @applied_patches.include?(target_method)
        adapter_class.class_eval do
          define_method("#{target_method}_with_arproxy") do |sql, name=nil, **kwargs|
            ::Arproxy.proxy_chain.connection = self
            _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
            self.send("#{target_method}_without_arproxy", _sql, _name, **kwargs)
          end
          alias_method :"#{target_method}_without_arproxy", target_method
          alias_method target_method, :"#{target_method}_with_arproxy"
        end
        @applied_patches << target_method
      end

      def apply_patch_binds(target_method)
        return if @applied_patches.include?(target_method)
        adapter_class.class_eval do
          define_method("#{target_method}_with_arproxy") do |sql, name=nil, binds=[], **kwargs|
            ::Arproxy.proxy_chain.connection = self
            _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
            self.send("#{target_method}_without_arproxy", _sql, _name, binds, **kwargs)
          end
          alias_method :"#{target_method}_without_arproxy", target_method
          alias_method target_method, :"#{target_method}_with_arproxy"
        end
        @applied_patches << target_method
      end
  end
end
