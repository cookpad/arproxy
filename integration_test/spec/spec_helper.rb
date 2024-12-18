require 'arproxy'
require 'active_record'

class Product < ActiveRecord::Base
end

class QueryLogger < Arproxy::Base
  def execute(sql, name = nil)
    @@log ||= []
    @@log << sql
    puts "QueryLogger: #{sql}"
    super
  end

  def self.log
    @@log
  end

  def self.reset!
    @@log = []
  end
end

class HelloProxy < Arproxy::Base
  def execute(sql, name = nil)
    super("#{sql} -- Hello Arproxy!", name)
  end
end
