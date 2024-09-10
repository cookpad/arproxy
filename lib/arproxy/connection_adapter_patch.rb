module Arproxy
  class ConnectionAdapterPatch
    attr_reader :adapter_class

    def initialize(adapter_class)
      @adapter_class = adapter_class
      @enabled_patches = Set.new
    end

    def enable!
      case adapter_class::ADAPTER_NAME
      when 'Mysql2', 'Trilogy' # known children of AbstractMysqlAdapter
        if ActiveRecord.version >= '7.0'
          enable_patch :raw_execute
        else
          enable_patch :execute
        end
      when 'PostgreSQL', 'SQLServer', 'SQLite' # known children of AbstractAdapter
        if ActiveRecord.version >= '7.1'
          enable_patch :raw_execute
          enable_patch :internal_exec_query
        else
          enable_patch :execute
          enable_patch :exec_query
        end
      else
        raise Arproxy::Error, "Unexpected connection adapter: #{adapter_class&.name}"
      end
      ::Arproxy.logger.debug("Arproxy: Enabled (#{adapter_class::ADAPTER_NAME})")
    end

    def disable!
      @enabled_patches.dup.each do |target_method|
        adapter_class.class_eval do
          if respond_to?(:"#{target_method}_with_arproxy")
            alias_method target_method, :"#{target_method}_without_arproxy"
            remove_method :"#{target_method}_with_arproxy"
          end
        end
        @enabled_patches.delete(target_method)
      end
      ::Arproxy.logger.debug("Arproxy: Disabled (#{adapter_class::ADAPTER_NAME})")
    end

    private
      def enable_patch(target_method)
        return if @enabled_patches.include?(target_method)

        adapter_class.class_eval do
          case target_method
          when :execute # for AbstractMysqlAdapter, ActiveRecord 6.1 and earlier
            def execute_with_arproxy(sql, name=nil, **kwargs) #
              ::Arproxy.proxy_chain.connection = self
              _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
              self.send(:execute_without_arproxy, _sql, _name, **kwargs)
            end
          when :exec_query # for AbstractAdapter, ActiveRecord 7.0 and earlier
            def exec_query_with_arproxy(sql, name=nil, binds=[], **kwargs) #
              ::Arproxy.proxy_chain.connection = self
              _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
              self.send(:exec_query_without_arproxy, _sql, _name, binds, **kwargs)
            end
          when :raw_execute
            def raw_execute_with_arproxy(sql, name=nil, **kwargs)
              ::Arproxy.proxy_chain.connection = self
              _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
              self.send(:raw_execute_without_arproxy, _sql, _name, **kwargs)
            end
          when :internal_exec_query
            def internal_exec_query_with_arproxy(sql, name=nil, binds=[], **kwargs)
              ::Arproxy.proxy_chain.connection = self
              _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
              self.send(:internal_exec_query_without_arproxy, _sql, _name, binds, **kwargs)
            end
          else
            raise ArgumentError, "Unsupported method to patch: #{target_method}"
          end

          alias_method :"#{target_method}_without_arproxy", target_method
          alias_method target_method, :"#{target_method}_with_arproxy"
        end

        @enabled_patches << target_method
      end
  end
end
