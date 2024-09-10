RSpec.shared_examples 'Arproxy does not break the original ActiveRecord functionality' do
  before do
    # CREATE
    ActiveRecord::Base.connection.create_table :products, force: true do |t|
      t.string :name
      t.integer :price
    end
    # INSERT
    Product.create(name: 'apple', price: 100)
    Product.create(name: 'banana', price: 200)
    Product.create(name: 'orange', price: 300)
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :products
  end

  context 'SELECT' do
    # it { expect(Product.where(name: ['apple', 'orange']).sum(:price)).to eq(400) }
    it { expect(Product.count).to eq(3) }
  end

  context 'UPDATE' do
    it do
      expect {
        Product.where(name: 'banana').update_all(price: 1000)
      }.to change {
        Product.find_by(name: 'banana').price
      }.from(200).to(1000)
    end
  end

  context 'DELETE' do
    it do
      expect {
        Product.where(name: 'banana').delete_all
      }.to change {
        Product.where(name: 'banana').exists?
      }.from(true).to(false)
    end
  end
end
