module Arproxy
  class Base
    attr_accessor :proxy_chain, :next_proxy

    def execute(sql, name=nil)
      next_proxy.execute sql, name
    end
  end
end
