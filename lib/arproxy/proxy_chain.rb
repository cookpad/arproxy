require_relative './chain_tail'
require_relative './connection_adapter_patch'

module Arproxy
  class ProxyChain
    attr_reader :head, :tail

    def initialize(config)
      @config = config
      setup
    end

    def setup
      @tail = ChainTail.new self
      @patch = ConnectionAdapterPatch.new(@config.adapter_class)
      @head = @config.proxies.reverse.inject(@tail) do |next_proxy, proxy_config|
        cls, options = proxy_config
        proxy = cls.new(*options)
        proxy.proxy_chain = self
        proxy.next_proxy = next_proxy
        proxy
      end
    end
    private :setup

    def reenable!
      disable!
      setup
      enable!
    end

    def enable!
      @patch.enable!
    end

    def disable!
      @patch.disable!
    end

    def connection
      Thread.current[:arproxy_connection]
    end

    def connection=(val)
      Thread.current[:arproxy_connection] = val
    end
  end
end
