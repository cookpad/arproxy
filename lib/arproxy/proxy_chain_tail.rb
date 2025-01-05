require_relative './proxy'
require_relative './query_context'

module Arproxy
  class ProxyChainTail < Proxy
    def execute(sql, context)
      unless context.instance_of?(QueryContext)
        raise Arproxy::Error, "`context` is expected a `Arproxy::QueryContext` but got `#{context.class}`"
      end

      if context.with_binds?
        context.raw_connection.send(context.execute_method_name, sql, context.name, context.binds, **context.kwargs)
      else
        context.raw_connection.send(context.execute_method_name, sql, context.name, **context.kwargs)
      end
    end
  end
end
