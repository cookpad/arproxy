require_relative './proxy'

module Arproxy
  class ProxyChainTail < Proxy
    def execute(sql, context)
      raw_connection = next_proxy
      if context.with_binds?
        raw_connection.send(context.execute_method_name, sql, context.name, context.binds, **context.kwargs)
      else
        raw_connection.send(context.execute_method_name, sql, context.name, **context.kwargs)
      end
    end
  end
end
