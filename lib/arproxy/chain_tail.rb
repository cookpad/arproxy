module Arproxy
  class ChainTail < Base
    def initialize(proxy_chain)
      self.proxy_chain = proxy_chain
    end

    def execute(sql, name=nil, **kwargs)
      self.proxy_chain.connection.execute_without_arproxy sql, name, **kwargs
    end

    private
    def raw_execute(sql, name, **kwargs)
      self.proxy_chain.connection.send :raw_execute_without_arproxy, sql, name, **kwargs
    end
  end
end
