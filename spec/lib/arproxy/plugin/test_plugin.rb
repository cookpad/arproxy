module Arproxy::Plugin
  class TestPlugin < Arproxy::Proxy
    Arproxy::Plugin.register(:test_plugin, self)

    def initialize(*options)
      @options = options
    end

    def execute(sql, context)
      context.name = "#{context.name}_PLUGIN"
      super("#{sql} /* options: #{@options.inspect} */", context)
    end
  end
end
