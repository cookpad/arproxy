module Arproxy
  class Proxy
    attr_reader :context, :next_proxy

    def initialize(next_proxy)
      @next_proxy = next_proxy
    end

    def execute(sql, context)
      next_proxy.execute(sql, context)
    end
  end
end
