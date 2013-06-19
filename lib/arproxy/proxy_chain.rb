module Arproxy
  autoload :ChainTail, "arproxy/chain_tail"

  class ProxyChain
    attr_reader :head, :tail
    attr_accessor :connection

    def initialize(config)
      @config = config
      setup
    end

    def setup
      @tail = ChainTail.new self
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
      @config.adapter_class.class_eval do
        def execute_with_arproxy(sql, name=nil)
          ::Arproxy.proxy_chain.connection = self
          ::Arproxy.proxy_chain.head.execute sql, name
        end
        alias_method :execute_without_arproxy, :execute
        alias_method :execute, :execute_with_arproxy
        ::Arproxy.logger.debug("Arproxy: Enabled")
      end
    end

    def disable!
      @config.adapter_class.class_eval do
        alias_method :execute, :execute_without_arproxy
        ::Arproxy.logger.debug("Arproxy: Disabled")
      end
    end
  end
end
