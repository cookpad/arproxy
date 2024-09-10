require_relative 'spec_helper'

context "SQLite3 (AR#{ar_version})" do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )

    Arproxy.configure do |config|
      config.adapter = 'sqlite3'
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
