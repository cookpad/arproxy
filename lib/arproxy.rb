require "logger"

module Arproxy
  autoload :Config, "arproxy/config"
  autoload :ProxyChain, "arproxy/proxy_chain"
  autoload :Error, "arproxy/error"
  autoload :Base, "arproxy/base"

  module_function
  def configure
    config = Config.new
    yield config
    @config = config
  end

  def enable!
    @proxy_chain = ProxyChain.new @config

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
    @proxy_chain = nil
    @config = nil
  end

  def logger
    @logger ||= begin
                  @config && @config.logger ||
                    defined?(::Rails) && ::Rails.logger ||
                    ::Logger.new(STDOUT)
                end
  end

  def proxy_chain
    @proxy_chain
  end
end

