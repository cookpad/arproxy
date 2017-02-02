module Arproxy
  class Config
    attr_accessor :adapter, :logger
    attr_reader :proxies
    attr_accessor :extra_methods

    def initialize
      @proxies = []
      @extra_methods = []
    end

    def use(proxy_class, *options)
      ::Arproxy.logger.debug("Arproxy: Mounting #{proxy_class.inspect} (#{options.inspect})")
      @proxies << [proxy_class, options]
    end

    def plugin(name, *options)
      plugin_class = Plugin.get(name)
      use(plugin_class, *options)
    end

    def adapter_class
      raise Arproxy::Error, "config.adapter must be set" unless @adapter
      case @adapter
      when String, Symbol
        camelized_adapter_name = @adapter.to_s.split("_").map(&:capitalize).join
        eval "::ActiveRecord::ConnectionAdapters::#{camelized_adapter_name}Adapter"
      when Class
        @adapter
      else
        raise Arproxy::Error, "unexpected config.adapter: #{@adapter}"
      end
    end
  end
end
