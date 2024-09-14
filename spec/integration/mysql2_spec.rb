require_relative '../spec_helper'

context "MySQL (AR#{ar_version})" do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'mysql2',
      host: ENV.fetch('MYSQL_HOST', '127.0.0.1'),
      port: ENV.fetch('MYSQL_PORT', '23306').to_i,
      database: 'arproxy_test',
      username: 'arproxy',
      password: ENV.fetch('ARPROXY_DB_PASSWORD')
    )

    Arproxy.configure do |config|
      config.adapter = 'mysql2'
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
