require "logger"

module Arproxy
  autoload :Config
  autoload :Proxy
  autoload :Error

  module_function
  def configure
    config = Config.new
    yield config
    @config = config
  end

  def enable!
    @proxy = Proxy.new @config
    @proxy.enable!
  end

  def disable!
    @proxy.disable! if @proxy
  end

  def logger
    @logger ||= ::Logger.new(STDOUT)
  end

  def chain_head
    @proxy.chain_head
  end
end

__END__
Arproxy.configure do |config|
  config.adapter = "mysql2"
  config.use Hoge
  config.use Moge
end

Arproxy.enable!
