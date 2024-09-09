require 'arproxy/connection_adapter_patches/base_patch'

module Arproxy
  module ConnectionAdapterPatches
    class SqlserverPatch < BasePatch
      def enable!
        adapter_class.class_eval do
          def raw_execute_with_arproxy(sql, name=nil, **kwargs)
            ::Arproxy.proxy_chain.connection = self
            _sql, _name = *::Arproxy.proxy_chain.head.execute(sql, name)
            self.send(:raw_execute_without_arproxy, _sql, _name, **kwargs)
          end
          alias_method :raw_execute_without_arproxy, :raw_execute
          alias_method :raw_execute, :raw_execute_with_arproxy
          ::Arproxy.logger.debug('Arproxy: Enabled')
        end
      end

      def disable!
        adapter_class.class_eval do
          alias_method :raw_execute, :raw_execute_without_arproxy
          ::Arproxy.logger.debug('Arproxy: Disabled')
        end
      end
    end
  end
end
