module Arproxy::Plugin
  class TestPlugin < Arproxy::Base
    Arproxy::Plugin.register(:test_plugin, self)

    def initialize(*options)
      @options = options
    end

    def execute(sql, name=nil)
      super("#{sql} /* options: #{@options.inspect} */", "#{name}_PLUGIN")
    end
  end
end
