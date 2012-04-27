module Arproxy
  class Config
    attr_accessor :adapter
    attr_reader :proxies

    def initialize
      @proxies = []
    end

    def use(proxy_class, *options)
      ::Arproxy.logger.debug("Arproxy: Mounting #{proxy_class.inspect} (#{options.inspect})")
      @proxies << [proxy_class, options]
    end
  end
end
