require 'arproxy/query_context'
require 'arproxy/proxy'

module Arproxy
  class ProxyChainHead < Proxy
    def execute_head_with_binds(raw_connection, execute_method_name, sql, name = nil, binds = [], **kwargs)
      context = QueryContext.new(
        raw_connection: raw_connection,
        execute_method_name: execute_method_name,
        with_binds: true,
        name: name,
        binds: binds,
        kwargs: kwargs,
      )
      execute(sql, context)
    end

    def execute_head(raw_connection, execute_method_name, sql, name = nil, **kwargs)
      context = QueryContext.new(
        raw_connection: raw_connection,
        execute_method_name: execute_method_name,
        with_binds: false,
        name: name,
        kwargs: kwargs,
      )
      execute(sql, context)
    end
  end
end
