module Arproxy::Plugin
  class Test < Arproxy::Base
    Arproxy::Plugin.register(:test, self)

    def initialize(*options)
      @options = options
    end

    def execute(sql, name=nil)
      {:sql => "#{sql}_PLUGIN", :name => "#{name}_PLUGIN", :options => @options}
    end
  end
end
