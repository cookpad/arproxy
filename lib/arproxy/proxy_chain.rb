module Arproxy
  autoload :ChainTail, "arproxy/chain_tail"

  class ProxyChain
    attr_reader :head, :tail
    attr_accessor :connection

    def initialize(config)
      @config = config
      setup_proxy_chain(@config)
    end

    def setup_proxy_chain(config)
      @tail = ChainTail.new self
      @head = config.proxies.reverse.inject(@tail) do |next_proxy, proxy_config|
        cls, options = proxy_config
        proxy = cls.new *options
        proxy.proxy_chain = self
        proxy.next_proxy = next_proxy
        proxy
      end
    end
    private :setup_proxy_chain

  end
end
