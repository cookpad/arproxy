module Arproxy
  autoload :ChainTail, "arproxy/chain_tail"

  class ProxyChain
    attr_reader :head, :tail

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
        def execute_with_arproxy(sql, name=nil, **kwargs)
          ::Arproxy.proxy_chain.connection = self
          ::Arproxy.proxy_chain.head.execute sql, name, **kwargs
        end
        alias_method :execute_without_arproxy, :execute
        alias_method :execute, :execute_with_arproxy

        if private_method_defined?(:raw_execute) # Rails 7.1+
          private
          def raw_execute_with_arproxy(sql, name, **kwargs)
            ::Arproxy.proxy_chain.connection = self
            ::Arproxy.proxy_chain.head.send :raw_execute, sql, name, **kwargs
          end
          alias_method :raw_execute_without_arproxy, :raw_execute
          alias_method :raw_execute, :raw_execute_with_arproxy
        end

        ::Arproxy.logger.debug("Arproxy: Enabled")
      end
    end

    def disable!
      @config.adapter_class.class_eval do
        alias_method :execute, :execute_without_arproxy
        if private_method_defined?(:raw_execute)
          private
          alias_method :raw_execute, :raw_execute_without_arproxy
        end
        ::Arproxy.logger.debug("Arproxy: Disabled")
      end
    end

    def connection
      Thread.current[:arproxy_connection]
    end

    def connection=(val)
      Thread.current[:arproxy_connection] = val
    end

  end
end
