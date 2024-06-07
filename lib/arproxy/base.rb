module Arproxy
  class Base
    attr_accessor :proxy_chain, :next_proxy

    def execute(sql, name=nil, **kwargs)
      next_proxy.execute sql, name, **kwargs
    end

    private
    def raw_execute(sql, name, **kwargs)
      next_proxy.send :raw_execute, sql, name, **kwargs
    end
  end
end
