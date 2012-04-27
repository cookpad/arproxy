module Arproxy
  class Config
    attr_accessor :adapter, :logger
    attr_reader :proxies

    def initialize
      @proxies = []
    end

    def use(proxy_class, *options)
      ::Arproxy.logger.debug("Arproxy: Mounting #{proxy_class.inspect} (#{options.inspect})")
      @proxies << [proxy_class, options]
    end

    def adapter_class
      raise Arproxy::Error, "config.adapter must be set" unless @adapter
      camelized_adapter_name = @adapter.split("_").map(&:capitalize).join
      eval "::ActiveRecord::ConnectionAdapters::#{camelized_adapter_name}Adapter"
    end
  end
end
