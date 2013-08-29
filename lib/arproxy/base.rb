module Arproxy
  class Base
    attr_accessor :proxy_chain, :next_proxy

    def method_missing(name, *args)
      next_proxy.send(name, *args)
    end
  end
end
