module Arproxy
  class ChainTail < Base
    def initialize(proxy_chain)
      self.proxy_chain = proxy_chain
    end

    def execute(sql, name=nil)
      [sql, name]
    end
  end
end
