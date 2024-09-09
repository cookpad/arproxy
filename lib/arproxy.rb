require 'logger'
require 'arproxy/base'
require 'arproxy/config'
require 'arproxy/proxy_chain'
require 'arproxy/error'
require 'arproxy/plugin'

module Arproxy
  @config = @enabled = nil

  module_function
  def clear_configuration
    @config = Config.new
  end

  def configure
    clear_configuration unless @config
    yield @config
  end

  def enable!
    if enable?
      Arproxy.logger.warn 'Arproxy has been already enabled'
      return
    end

    unless @config
      raise Arproxy::Error, 'Arproxy should be configured'
    end

    @proxy_chain = ProxyChain.new @config
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

    clear_configuration

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
end
