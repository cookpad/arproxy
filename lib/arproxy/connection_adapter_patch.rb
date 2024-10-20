module Arproxy
  class ConnectionAdapterPatch
    attr_reader :adapter_class

    def initialize(adapter_class)
      @adapter_class = adapter_class
      @applied_patches = Set.new
    end

    def self.register_patches(adapter_name, patches: [], binds_patches: [])
      @@patches ||= {}
      @@patches[adapter_name] = {
        patches: patches,
        binds_patches: binds_patches
      }
    end

    if ActiveRecord.version >= Gem::Version.new('7.0')
      register_patches('Mysql2', patches: [:raw_execute], binds_patches: [])
      register_patches('Trilogy', patches: [:raw_execute], binds_patches: [])
    else
      register_patches('Mysql2', patches: [:execute], binds_patches: [])
      register_patches('Trilogy', patches: [:raw_execute], binds_patches: [])
    end

    if ActiveRecord.version >= Gem::Version.new('7.1')
      register_patches('PostgreSQL', patches: [:raw_execute], binds_patches: [:exec_no_cache, :exec_cache])
      register_patches('SQLServer', patches: [:raw_execute], binds_patches: [:internal_exec_query])
      register_patches('SQLite', patches: [:raw_execute], binds_patches: [:internal_exec_query])
    else
      register_patches('PostgreSQL', patches: [:execute], binds_patches: [:exec_no_cache, :exec_cache])
      register_patches('SQLServer', patches: [:execute], binds_patches: [:exec_query])
      register_patches('SQLite', patches: [:execute], binds_patches: [:exec_query])
    end

    def enable!
      patches = @@patches[adapter_class::ADAPTER_NAME]
      if patches
        patches[:patches]&.each do |patch|
          apply_patch patch
        end
        patches[:binds_patches]&.each do |binds_patch|
          apply_patch_binds binds_patch
        end
      else
        raise Arproxy::Error, "Unexpected connection adapter: patches not registered for #{adapter_class&.name}"
      end
      ::Arproxy.logger.debug("Arproxy: Enabled (#{adapter_class::ADAPTER_NAME})")
    end

    def disable!
      @applied_patches.dup.each do |target_method|
        adapter_class.class_eval do
          if instance_methods.include?(:"#{target_method}_with_arproxy")
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
          break if instance_methods.include?(:"#{target_method}_with_arproxy")
          define_method("#{target_method}_with_arproxy") do |sql, name=nil, **kwargs|
            ::Arproxy.proxy_chain.connection = self
            proxy_chain_result = ::Arproxy.proxy_chain.head.execute(sql, name)
            if proxy_chain_result && proxy_chain_result.is_a?(Array)
              _sql, _name = proxy_chain_result
              self.send("#{target_method}_without_arproxy", _sql, _name, **kwargs)
            else
              nil
            end
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
            proxy_chain_result = ::Arproxy.proxy_chain.head.execute(sql, name)
            if proxy_chain_result && proxy_chain_result.is_a?(Array)
              _sql, _name = proxy_chain_result
              self.send("#{target_method}_without_arproxy", _sql, _name, binds, **kwargs)
            else
              nil
            end
          end
          alias_method :"#{target_method}_without_arproxy", target_method
          alias_method target_method, :"#{target_method}_with_arproxy"
        end
        @applied_patches << target_method
      end
  end
end
