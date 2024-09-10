module Arproxy
  module ConnectionAdapterPatches
    class BasePatch
      attr_reader :adapter_class

      def initialize(adapter_class)
        @adapter_class = adapter_class
        @enabled_patches = Set.new
      end

      def enable!
        raise NotImplementedError
      end

      def disable!
        @enabled_patches.each do |target_method|
          adapter_class.class_eval do
            if respond_to?(:"#{target_method}_with_arproxy")
              alias_method target_method, :"#{target_method}_without_arproxy"
              remove_method :"#{target_method}_with_arproxy"
            end
          end
          ::Arproxy.logger.debug("Arproxy: Disabled (#{adapter_class::ADAPTER_NAME})")
        end
      end

      private
        def enable_patches(*target_methods)
          target_methods.each do |target_method|
            enable_patch(target_method)
          end
          ::Arproxy.logger.debug("Arproxy: Enabled (#{adapter_class::ADAPTER_NAME})")
        end

        def enable_patch(target_method)
          return if @enabled_patches.include?(target_method)

          adapter_class.class_eval do
            case target_method
            when :execute # for AbstractMysqlAdapter, ActiveRecord 6.1
              def execute_with_arproxy(sql, name=nil, **kwargs) #
                ::Arproxy.proxy_chain.connection = self
                _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
                self.send(:execute_without_arproxy, _sql, _name, **kwargs)
              end
            when :exec_query # for AbstractAdapter, ActiveRecord 6.1
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
end
