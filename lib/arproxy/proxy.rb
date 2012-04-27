module Arproxy
  autoload :ChainTail

  class Proxy
    attr_reader :chain_head

    def initialize(config)
      @config = config
      setup_proxy_chain(config)
    end

    def setup_proxy_chain
      # TODO execute時にadapterを指定したい(connectionが動的に変わるから)
      tail = [ChainTail, nil]
      @chain_head = @config.proxies.reverse.inject(tail) do |next_proxy, proxy|
        cls, options = proxy
        cls.new next_proxy, *options
      end
    end
    private :setup_proxy_chain

    def enable!
      adapter_class.class_eval do
        def execute_with_arproxy(sql, name=nil)
          ::Arproxy.chain_head.execute self, sql, name
        end
        alias_method :execute_without_arproxy, :execute
        alias_method :execute, :execute_with_arproxy
        ::Arproxy.logger.debug("Arproxy: Enabled")
      end
    end

    def disable!
      adapter_class.class_eval do
        alias_method :execute, :execute_without_arproxy
        ::Arproxy.logger.debug("Arproxy: Disabled")
      end
    end

    def adapter_class
      raise Arproxy::Error, "config.adapter must be set" unless @config.adapter
      "::ActiveRecord::ConnectionAdapters::#{@config.adapter.camelcase}Adapter".constantize
    end
  end
end
