require "spec_helper"

describe Arproxy do
  before do
    allow(Arproxy).to receive(:logger) { Logger.new('/dev/null') }
  end

  class ProxyA < Arproxy::Base
    def execute(sql, name)
      super "#{sql}_A", "#{name}_A"
    end
  end

  class ProxyB < Arproxy::Base
    def initialize(opt=nil)
      @opt = opt
    end

    def execute(sql, name)
      super "#{sql}_B#{@opt}", "#{name}_B#{@opt}"
    end
  end

  module ::ActiveRecord
    module ConnectionAdapters
      class DummyAdapter
        def execute(sql, name = nil)
          {:sql => sql, :name => name}
        end
      end
    end
  end

  let(:connection) { ::ActiveRecord::ConnectionAdapters::DummyAdapter.new }
  subject { connection.execute "SQL", "NAME" }
  after(:each) do
    Arproxy.disable!
  end

  context "with a proxy" do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.use ProxyA
      end
      Arproxy.enable!
    end

    it { should == {:sql => "SQL_A", :name => "NAME_A"} }
  end

  context "with 2 proxies" do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.use ProxyA
        config.use ProxyB
      end
      Arproxy.enable!
    end

    it { should == {:sql => "SQL_A_B", :name => "NAME_A_B"} }
  end

  context "with 2 proxies which have an option" do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.use ProxyA
        config.use ProxyB, 1
      end
      Arproxy.enable!
    end

    it { should == {:sql => "SQL_A_B1", :name => "NAME_A_B1"} }
  end

  context do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.use ProxyA
      end
    end

    context "enable -> disable" do
      before do
        Arproxy.enable!
        Arproxy.disable!
      end
      it { should == {:sql => "SQL", :name => "NAME"} }
    end

    context "enable -> enable" do
      before do
        Arproxy.enable!
        Arproxy.enable!
      end
      it { should == {:sql => "SQL_A", :name => "NAME_A"} }
    end

    context "enable -> disable -> disable" do
      before do
        Arproxy.enable!
        Arproxy.disable!
        Arproxy.disable!
      end
      it { should == {:sql => "SQL", :name => "NAME"} }
    end

    context "enable -> disable -> enable" do
      before do
        Arproxy.enable!
        Arproxy.disable!
        Arproxy.enable!
      end
      it { should == {:sql => "SQL_A", :name => "NAME_A"} }
    end

    context "re-configure" do
      before do
        Arproxy.configure do |config|
          config.use ProxyB
        end
        Arproxy.enable!
      end
      it { should == {:sql => "SQL_A_B", :name => "NAME_A_B"} }
    end
  end

  context "use a plug-in" do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.plugin :test, :option_a, :option_b
      end
      Arproxy.enable!
    end

    it { should == {:sql => "SQL_PLUGIN", :name => "NAME_PLUGIN", :options => [:option_a, :option_b]} }
  end

  context "ProxyChain thread-safety" do
    class ProxyWithConnectionId < Arproxy::Base
      def execute(sql, name)
        sleep 0.1
        super "#{sql} /* connection_id=#{self.proxy_chain.connection.object_id} */", name
      end
    end

    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = "dummy"
        config.use ProxyWithConnectionId
      end
      Arproxy.enable!
    end

    context "with two threads" do
      let!(:thr1) { Thread.new { connection.dup.execute 'SELECT 1' } }
      let!(:thr2) { Thread.new { connection.dup.execute 'SELECT 1' } }

      it { expect(thr1.value).not_to eq(thr2.value) }
    end
  end
end
