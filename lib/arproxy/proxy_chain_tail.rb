require_relative './proxy'

module Arproxy
  class ProxyChainTail < Proxy
    def execute(sql, context)
      if context.with_binds?
        context.raw_connection.send(context.execute_method_name, sql, context.name, context.binds, **context.kwargs)
      else
        context.raw_connection.send(context.execute_method_name, sql, context.name, **context.kwargs)
      end
    end
  end
end
