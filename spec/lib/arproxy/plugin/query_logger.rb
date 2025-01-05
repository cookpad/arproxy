require 'arproxy/plugin'

class QueryLogger < Arproxy::Proxy
  Arproxy::Plugin.register(:query_logger, self)

  def execute(sql, context)
    @@log ||= []
    @@log << sql
    if ENV['DEBUG']
      puts "QueryLogger: [#{context.name}] #{sql}"
    end
    super
  end

  def self.log
    @@log
  end

  def self.reset!
    @@log = []
  end
end
