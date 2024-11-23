require_relative './spec_helper'

describe Arproxy::Config do
  describe '#adapter default value' do
    subject { Arproxy::Config.new.adapter }

    context 'when Rails is defined' do
      let(:rails) { Module.new }

      around do |example|
        Object.const_set('Rails', rails)
        example.run
        Object.send(:remove_const, 'Rails')
      end

      before do
        allow(rails).to receive_message_chain('application.config_for') { database_config }
      end

      context 'when adapter is configured in database.yml' do
        let(:database_config) { { 'adapter' => 'mysql2' } }

        it { should == 'mysql2' }
      end

      context "when adapter isn't configured in database.yml" do
        let(:database_config) { {} }

        it { should == nil }
      end
    end

    context "when Rails isn't defined" do
      it { should == nil }
    end
  end

  describe '#adapter_class' do
    subject { config.adapter_class }
    let(:config) { Arproxy::Config.new }

    before do
      config.adapter = adapter
    end

    context "when adapter is configured as 'mysql2'" do
      let(:adapter) { 'mysql2' }
      let(:mysql2_class) { Class.new }

      before do
        stub_const('ActiveRecord::ConnectionAdapters::Mysql2Adapter', mysql2_class)
      end

      it { should == mysql2_class }
    end

    context "when adapter is configured as 'sqlite3'" do
      let(:adapter) { 'sqlite3' }
      let(:sqlite3_class) { Class.new }

      before do
        stub_const('ActiveRecord::ConnectionAdapters::SQLite3Adapter', sqlite3_class)
      end

      it { should == sqlite3_class }
    end

    context "when adapter is configured as 'sqlserver'" do
      let(:adapter) { 'sqlserver' }
      let(:sqlserver_class) { Class.new }

      before do
        stub_const('ActiveRecord::ConnectionAdapters::SQLServerAdapter', sqlserver_class)
      end

      it { should == sqlserver_class }
    end

    context "when adapter is configured as 'postgresql'" do
      let(:adapter) { 'postgresql' }
      let(:postgresql_class) { Class.new }

      before do
        stub_const('ActiveRecord::ConnectionAdapters::PostgreSQLAdapter', postgresql_class)
      end

      it { should == postgresql_class }
    end
  end
end
