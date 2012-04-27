module Arproxy
  class ChainTail < Base
    def initialize(proxy_chain)
      self.proxy_chain = proxy_chain
    end

    def execute(sql, name=nil)
      self.proxy_chain.connection.execute_without_arproxy sql, name
    end
  end
end
