module Arproxy
  class Proxy
    attr_accessor :context, :next_proxy

    def execute(sql, context)
      next_proxy.execute(sql, context)
    end
  end
end
