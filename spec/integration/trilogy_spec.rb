require_relative '../spec_helper'

context "Trilogy (AR#{ar_version})", if: ActiveRecord.version >= '7.1' do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'trilogy',
      host: ENV.fetch('MYSQL_HOST', '127.0.0.1'),
      port: ENV.fetch('MYSQL_PORT', '23306').to_i,
      database: 'arproxy_test',
      username: 'arproxy',
      password: ENV.fetch('ARPROXY_DB_PASSWORD')
    )

    Arproxy.configure do |config|
      config.adapter = 'trilogy'
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
