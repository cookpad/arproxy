require 'logger'
require 'arproxy/base'
require 'arproxy/config'
require 'arproxy/proxy_chain'
require 'arproxy/error'
require 'arproxy/plugin'

module Arproxy
  @config = nil
  @enabled = nil
  @patch = nil

  module_function

    def clear_configuration
      @config = nil
    end

    def configure
      @config ||= Config.new
      yield @config
    end

    def enable!
      if enable?
        Arproxy.logger.warn 'Arproxy has already been enabled'
        return
      end

      unless @config
        raise Arproxy::Error, 'Arproxy has not been configured'
      end

      @patch = ConnectionAdapterPatch.new(@config.adapter_class)
      @proxy_chain = ProxyChain.new(@config, @patch)
      @proxy_chain.enable!

      @enabled = true
    end

    def disable!
      unless enable?
        Arproxy.logger.warn 'Arproxy is not enabled yet'
        return
      end

      if @proxy_chain
        @proxy_chain.disable!
        @proxy_chain = nil
      end

      @enabled = false
    end

    def enable?
      !!@enabled
    end

    def reenable!
      if enable?
        @proxy_chain.reenable!
      else
        enable!
      end
    end

    def logger
      @logger ||= @config && @config.logger ||
                      defined?(::Rails) && ::Rails.logger ||
                      ::Logger.new(STDOUT)
    end

    def proxy_chain
      @proxy_chain
    end

    def connection_adapter_patch
      @patch
    end
end
