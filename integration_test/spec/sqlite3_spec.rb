require_relative 'spec_helper'
require 'sqlite3'

context 'SQLite3' do
  before(:all) do
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )

    Arproxy.configure do |config|
      config.adapter = 'sqlite3'
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
    expect(QueryLogger.log[1]).to match(/\ASELECT "products".* FROM "products" ORDER BY "products"."id" ASC LIMIT .* -- Hello Arproxy!\z/)
  end
end
