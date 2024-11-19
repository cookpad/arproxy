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

def wait_for_db(host, port, interval = 0.2, timeout = 10)
  print "\nWaiting for DB on #{host}:#{port}..." if ENV['DEBUG']
  Timeout.timeout(timeout) do
    loop do
      TCPSocket.new(host, port).close
      puts 'ok' if ENV['DEBUG']
      break
    rescue Errno::ECONNREFUSED
      print '.' if ENV['DEBUG']
      sleep interval
    end
  end
rescue Timeout::Error
  raise "Timeout waiting for DB on #{host}:#{port}"
end
