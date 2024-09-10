require 'arproxy'
require 'active_record'
require 'dotenv/load'

def ar_version
  "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
end

class Product < ActiveRecord::Base
end

class QueryLogger < Arproxy::Base
  def execute(sql, name = nil)
    @@log ||= []
    @@log << sql
    puts "QueryLogger: [#{name}] #{sql}"
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
