require 'active_record'
require 'active_record/base'

module Arproxy
  class Config
    attr_accessor :adapter, :logger
    attr_reader :proxies

    def initialize
      @proxies = []
      if defined?(Rails)
        @adapter = Rails.application.config_for(:database)['adapter']
      end
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
      raise Arproxy::Error, 'config.adapter must be set' unless @adapter
      case @adapter
      when String, Symbol
        eval "::ActiveRecord::ConnectionAdapters::#{camelized_adapter_name}Adapter"
      when Class
        @adapter
      else
        raise Arproxy::Error, "unexpected config.adapter: #{@adapter}"
      end
    end

    private

      def camelized_adapter_name
        adapter_name = @adapter.to_s.split('_').map(&:capitalize).join

        case adapter_name
        when 'Sqlite3'
          'SQLite3'
        when 'Sqlserver'
          'SQLServer'
        when 'Postgresql'
          'PostgreSQL'
        else
          adapter_name
        end
      end
  end
end
