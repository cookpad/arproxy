module Arproxy
  class ChainTail < Base
    def initialize(proxy_chain)
      self.proxy_chain = proxy_chain
    end

    def method_missing(name, connection, *args)
      connection.send("#{name}_without_arproxy", *args)
    end
  end
end
