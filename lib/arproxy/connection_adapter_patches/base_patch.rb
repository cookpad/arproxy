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

      protected
        def enable_patches(*target_methods)
          target_methods.each do |target_method|
            enable_patch(target_method)
          end
          ::Arproxy.logger.debug("Arproxy: Enabled (#{adapter_class::ADAPTER_NAME})")
        end

        def enable_patch(target_method)
          return if @enabled_patches.include?(target_method)

          case target_method
          when :raw_execute
            adapter_class.class_eval do
              def raw_execute_with_arproxy(sql, name=nil, **kwargs)
                ::Arproxy.proxy_chain.connection = self
                _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
                self.send(:raw_execute_without_arproxy, _sql, _name, **kwargs)
              end
              alias_method :raw_execute_without_arproxy, :raw_execute
              alias_method :raw_execute, :raw_execute_with_arproxy
            end
          when :internal_exec_query
            adapter_class.class_eval do
              def internal_exec_query_with_arproxy(sql, name=nil, binds=[], **kwargs)
                ::Arproxy.proxy_chain.connection = self
                _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
                self.send(:internal_exec_query_without_arproxy, _sql, _name, binds, **kwargs)
              end
              alias_method :internal_exec_query_without_arproxy, :internal_exec_query
              alias_method :internal_exec_query, :internal_exec_query_with_arproxy
            end
          else
            raise ArgumentError, "Unsupported method to patch: #{target_method}"
          end

          @enabled_patches << target_method
        end
    end
  end
end
