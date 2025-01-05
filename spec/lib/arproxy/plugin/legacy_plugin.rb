module Arproxy::Plugin
  class LegacyPlugin < Arproxy::Base
    Arproxy::Plugin.register(:legacy_plugin, self)

    def execute(sql, name)
      super("#{sql} /* legacy_plugin */", name)
    end
  end
end
