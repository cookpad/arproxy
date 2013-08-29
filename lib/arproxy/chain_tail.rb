module Arproxy
  class ChainTail < Base
    def initialize(proxy_chain)
      self.proxy_chain = proxy_chain
    end

    def method_missing(name, *args)
      self.proxy_chain.connection.send("#{name}_without_arproxy", *args)
    end
  end
end
