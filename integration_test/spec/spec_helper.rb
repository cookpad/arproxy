require 'arproxy'
require 'active_record'
require 'dotenv/load'
require_relative './shared_examples/custom_proxies'
require_relative './shared_examples/active_record_functions'

Arproxy.logger.level = Logger::WARN unless ENV['DEBUG']

def ar_version
  "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}"
end

def cleanup_activerecord
  ActiveRecord::Base.connection.close
  ActiveRecord::Base.connection.clear_cache!
  ActiveRecord::Base.descendants.each(&:reset_column_information)
  ActiveRecord::Base.connection.schema_cache.clear!
end
