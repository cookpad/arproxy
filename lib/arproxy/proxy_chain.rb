module Arproxy
  autoload :ChainTail, "arproxy/chain_tail"

  class ProxyChain
    attr_reader :head, :tail

    def initialize(config)
      @config = config
      setup
    end

    def setup
      @tail = ChainTail.new(self)
      @head = @config.proxies.reverse.inject(@tail) do |next_proxy, proxy_config|
        cls, options = proxy_config
        proxy = cls.new(*options)
        proxy.proxy_chain = self
        proxy.next_proxy = next_proxy
        proxy
      end
    end
    private :setup

    def proxy_methods
      [:execute]+@config.extra_methods
    end
    private :proxy_methods

    def reenable!
      disable!
      setup
      enable!
    end

    def enable!
      proxy_methods.each do |name|
        @config.adapter_class.class_eval do
          define_method "#{name}_with_arproxy" do |*args|
            ::Arproxy.proxy_chain.head.send(name, self, *args)
          end
          alias_method "#{name}_without_arproxy", name
          alias_method name, "#{name}_with_arproxy"
        end
      end
      ::Arproxy.logger.debug("Arproxy: Enabled")
    end

    def disable!
      proxy_methods.each do |name|
        @config.adapter_class.class_eval do
          alias_method name, "#{name}_without_arproxy"
        end
      end
      ::Arproxy.logger.debug("Arproxy: Disabled")
    end
  end
end
