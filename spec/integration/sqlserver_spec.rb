require_relative '../spec_helper'

context "SQLServer (AR#{ar_version})" do
  before(:all) do
    if ActiveRecord.version >= Gem::Version.new('7.2')
      ActiveRecord::ConnectionAdapters.register(
        'sqlserver',
        'ActiveRecord::ConnectionAdapters::SQLServerAdapter',
        'active_record/connection_adapters/sqlserver_adapter'
      )
    end

    host = ENV.fetch('MSSQL_HOST', '127.0.0.1')
    port = ENV.fetch('MSSQL_PORT', '21433').to_i
    wait_for_db(host, port)

    ActiveRecord::Base.establish_connection(
      adapter: 'sqlserver',
      host: host,
      port: port,
      database: 'arproxy_test',
      username: 'arproxy',
      password: ENV.fetch('ARPROXY_DB_PASSWORD')
    )

    Arproxy.configure do |config|
      config.adapter = 'sqlserver'
      config.use HelloProxy
      config.plugin :query_logger
    end
    Arproxy.enable!
  end

  after(:all) do
    cleanup_activerecord
    Arproxy.disable!
    Arproxy.clear_configuration
  end

  it_behaves_like 'Arproxy does not break the original ActiveRecord functionality'
  it_behaves_like 'Custom proxies work expectedly'
end
