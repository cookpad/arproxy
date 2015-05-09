module Arproxy
  module Plugin
    class << self
      def register(name, klass)
        name = name.to_s
        @plugins ||= {}

        if @plugins.has_key?(name)
          raise Arproxy::Error, "Plugin has already been registered: #{name}"
        end

        @plugins[name] = klass
      end

      def get(name)
        name = name.to_s
        require "arproxy/plugin/#{name}"
        plugin = @plugins[name]

        unless plugin
          raise Arproxy::Error, "Plugin is not found: #{name}"
        end

        plugin
      end
    end
  end
end
