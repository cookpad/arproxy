require "logger"
require "arproxy/base"
require "arproxy/config"
require "arproxy/proxy_chain"
require "arproxy/error"
require "arproxy/plugin"
require "active_record"
require "active_support"

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
      Arproxy.logger.warn "Arproxy has been already enabled"
      return
    end

    unless @config
      raise Arproxy::Error, "Arproxy should be configured"
    end

    if ActiveRecord.autoload? :Base
      ActiveSupport.on_load(:active_record, yield: true) do
        @proxy_chain = ProxyChain.new @config
        @proxy_chain.enable!
      end
    else
      @proxy_chain = ProxyChain.new @config
      @proxy_chain.enable!
    end

    @enabled = true
  end

  def disable!
    unless enable?
      Arproxy.logger.warn "Arproxy is not enabled yet"
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
