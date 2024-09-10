require 'arproxy/plugin'

class QueryLogger < Arproxy::Base
  Arproxy::Plugin.register(:query_logger, self)

  def execute(sql, name = nil)
    @@log ||= []
    @@log << sql
    if ENV['DEBUG']
      puts "QueryLogger: [#{name}] #{sql}"
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
