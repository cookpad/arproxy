require_relative '../spec_helper'
require 'trilogy'

context "Trilogy (AR#{ar_version})", if: ActiveRecord.version >= '7.1' do
  before(:all) do
    host = ENV.fetch('MYSQL_HOST', '127.0.0.1')
    port = ENV.fetch('MYSQL_PORT', '23306').to_i
    wait_for_db(host, port)

    mysql_data_dir = File.expand_path('../../db/mysql/data', __dir__)
    ActiveRecord::Base.establish_connection(
      adapter: 'trilogy',
      host: host,
      port: port,
      ssl: true,
      ssl_mode: Trilogy::SSL_VERIFY_CA,
      tls_min_version: Trilogy::TLS_VERSION_12,
      ssl_ca: File.join(mysql_data_dir, 'ca.pem'),
      ssl_cert: File.join(mysql_data_dir, 'client-cert.pem'),
      ssl_key: File.join(mysql_data_dir, 'client-key.pem'),
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
