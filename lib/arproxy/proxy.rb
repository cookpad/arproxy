require 'arproxy/query_context'

module Arproxy
  class Proxy
    attr_accessor :context, :next_proxy

    def execute(sql, context)
      unless context.instance_of?(QueryContext)
        raise Arproxy::Error, "`context` is expected a `Arproxy::QueryContext` but got `#{context.class}`"
      end

      next_proxy.execute(sql, context)
    end
  end
end
