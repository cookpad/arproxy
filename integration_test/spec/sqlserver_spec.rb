require_relative 'spec_helper'

context 'SQLServer' do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlserver',
      host: ENV.fetch('MSSQL_HOST', '127.0.0.1'),
      port: ENV.fetch('MSSQL_PORT', '21433').to_i,
      database: 'arproxy_test',
      username: 'arproxy',
      password: ENV.fetch('ARPROXY_DB_PASSWORD')
    )

    Arproxy.configure do |config|
      config.adapter = 'sqlserver'
      config.use HelloProxy
      config.use QueryLogger
    end
    Arproxy.enable!

    ActiveRecord::Base.connection.create_table :products, force: true do |t|
      t.string :name
      t.integer :price
    end

    Product.create(name: 'apple', price: 100)
    Product.create(name: 'banana', price: 200)
    Product.create(name: 'orange', price: 300)
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :products
    ActiveRecord::Base.connection.close
    Arproxy.disable!
  end

  before(:each) do
    QueryLogger.reset!
  end

  it do
    expect(QueryLogger.log.size).to eq(0)

    expect(Product.count).to eq(3)
    expect(Product.first.name).to eq('apple')

    expect(QueryLogger.log.size).to eq(2)
    expect(QueryLogger.log[0]).to eq('SELECT COUNT(*) FROM "products" -- Hello Arproxy!')
    expect(QueryLogger.log[1]).to eq('SELECT "products".* FROM "products" ORDER BY "products"."id" ASC LIMIT $1 -- Hello Arproxy!')
  end
end
