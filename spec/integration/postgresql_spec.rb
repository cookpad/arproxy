require_relative '../spec_helper'

context "PostgreSQL (AR#{ar_version})" do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'postgresql',
      host: ENV.fetch('POSTGRES_HOST', '127.0.0.1'),
      port: ENV.fetch('POSTGRES_PORT', '25432').to_i,
      database: 'arproxy_test',
      username: 'arproxy',
      password: ENV.fetch('ARPROXY_DB_PASSWORD')
    )

    Arproxy.configure do |config|
      config.adapter = 'postgresql'
      config.use HelloProxy
      config.plugin :query_logger
    end
    Arproxy.enable!
  end

  after(:all) do
    cleanup_activerecord
    Arproxy.disable!
  end

  it_behaves_like 'Arproxy does not break the original ActiveRecord functionality'
  it_behaves_like 'Custom proxies work expectedly'
end
