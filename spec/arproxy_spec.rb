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

  class ProxyC < Arproxy::Base
    private def raw_execute(sql, name, **kwargs)
      super "#{sql}_C", "#{name}_C"
    end
  end

  class ProxyD < Arproxy::Base
    def initialize(opt=nil)
      @opt = opt
    end
    private def raw_execute(sql, name, **kwargs)
      super "#{sql}_D#{@opt}", "#{name}_D#{@opt}"
    end
  end

  module ::ActiveRecord
    module ConnectionAdapters
      # for ActiveRecord version <= 7.0.x
      class DummyAdapter
        def execute(sql, name = nil)
          {:sql => sql, :name => name}
        end
      end

      # for ActiveRecord version >= 7.1.x
      class NewDummyAdapter
        def execute(sql, name = nil)
          raw_execute(sql, name)
        end

        private def raw_execute(sql, name, async: false, materialize_transactions: true)
          {:sql => sql, :name => name}
        end
      end
    end
  end

  let(:connection) { ::ActiveRecord::ConnectionAdapters::DummyAdapter.new }
  after(:each) do
    Arproxy.disable!
  end

  describe "#execute" do
    subject { connection.execute "SQL", "NAME" }

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

  let(:new_adapter_connection) { ::ActiveRecord::ConnectionAdapters::NewDummyAdapter.new }
  describe "#execute for ActiveRecord version >= 7.1.x" do
    subject { new_adapter_connection.send :execute, "SQL", "NAME" }

    context "with a proxy" do
      before do
        Arproxy.clear_configuration
        Arproxy.configure do |config|
          config.adapter = "new_dummy"
          config.use ProxyC
        end
        Arproxy.enable!
      end

      it { should == {:sql => "SQL_C", :name => "NAME_C"} }
    end

    context "with 2 proxies which have an option" do
      before do
        Arproxy.clear_configuration
        Arproxy.configure do |config|
          config.adapter = "new_dummy"
          config.use ProxyC
          config.use ProxyD, 1
        end
        Arproxy.enable!
      end

      it { should == {:sql => "SQL_C_D1", :name => "NAME_C_D1"} }
    end

    context do
      before do
        Arproxy.clear_configuration
        Arproxy.configure do |config|
          config.adapter = "new_dummy"
          config.use ProxyC
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
        it { should == {:sql => "SQL_C", :name => "NAME_C"} }
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
        it { should == {:sql => "SQL_C", :name => "NAME_C"} }
      end

      context "re-configure" do
        before do
          Arproxy.configure do |config|
            config.use ProxyD
          end
          Arproxy.enable!
        end
        it { should == {:sql => "SQL_C_D", :name => "NAME_C_D"} }
      end
    end

    context "use a plug-in" do
      before do
        Arproxy.clear_configuration
        Arproxy.configure do |config|
          config.adapter = "new_dummy"
          config.plugin :test, :option_a, :option_b
        end
        Arproxy.enable!
      end

      it { should == {:sql => "SQL_PLUGIN", :name => "NAME_PLUGIN", :options => [:option_a, :option_b]} }
    end

    context "ProxyChain thread-safety" do
      class ProxyWithConnectionId < Arproxy::Base
        private

        def raw_execute(sql, name, **kwargs)
          sleep 0.1
          super "#{sql} /* connection_id=#{self.proxy_chain.connection.object_id} */", name, **kwargs
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
end
