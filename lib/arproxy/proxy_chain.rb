require 'arproxy/proxy_chain_tail'
require 'arproxy/connection_adapter_patch'

module Arproxy
  class ProxyChain
    attr_reader :head, :tail, :patch

    def initialize(config, patch)
      @config = config
      @patch = patch
      setup
    end

    def setup
      @tail = ProxyChainTail.new
      @head = @config.proxies.reverse.inject(@tail) do |next_proxy, proxy_config|
        cls, options = proxy_config
        proxy = cls.new(*options)
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
  end
end
