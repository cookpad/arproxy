require_relative './legacy_chain_tail'
require_relative './legacy_connection_adapter_patch'

module Arproxy
  class LegacyProxyChain
    attr_reader :head, :tail, :patch

    def initialize(config, patch)
      @config = config
      @patch = patch
      setup
    end

    def setup
      @tail = LegacyChainTail.new self
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
