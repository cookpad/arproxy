module Arproxy
  class Base
    attr_accessor :proxy_chain, :next_proxy

    def execute(sql, name=nil, **kwargs)
      next_proxy.execute sql, name, **kwargs
    end
  end
end
