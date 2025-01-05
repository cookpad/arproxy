require_relative './spec_helper'

describe Arproxy do
  before do
    allow(Arproxy).to receive(:logger) { Logger.new('/dev/null') }
  end

  class LegacyProxyA < Arproxy::Base
    def execute(sql, name)
      super "#{sql}_A", "#{name}_A"
    end
  end

  class LegacyProxyB < Arproxy::Base
    def initialize(opt=nil)
      @opt = opt
    end

    def execute(sql, name)
      super "#{sql}_B#{@opt}", "#{name}_B#{@opt}"
    end
  end

  class ProxyA < Arproxy::Proxy
    def execute(sql, context)
      context.name = "#{context.name}_A"
      super "#{sql}_A", context
    end
  end

  class ProxyB < Arproxy::Proxy
    def initialize(opt=nil)
      @opt = opt
    end

    def execute(sql, context)
      context.name = "#{context.name}_B#{@opt}"
      super "#{sql}_B#{@opt}", context
    end
  end

  module ::ActiveRecord
    module ConnectionAdapters
      class DummyAdapter
        ADAPTER_NAME = 'Dummy'

        def execute1(sql, name = nil, **kwargs)
          { sql: sql, name: name, kwargs: kwargs }
        end

        def execute2(sql, name = nil, binds = [], **kwargs)
          { sql: sql, name: name, binds: binds, kwargs: kwargs }
        end
      end
      Arproxy::ConnectionAdapterPatch.register_patches('Dummy', patches: [:execute1], binds_patches: [:execute2])
    end
  end

  let(:connection) { ::ActiveRecord::ConnectionAdapters::DummyAdapter.new }
  after(:each) do
    Arproxy.disable!
  end

  context 'with a proxy' do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use ProxyA
      end
      Arproxy.enable!
    end

    it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A', name: 'NAME_A', kwargs: {} }) }
    it { expect(connection.execute1('SQL', 'NAME', a: 1, b: 2)).to eq({ sql: 'SQL_A', name: 'NAME_A', kwargs: { a: 1, b: 2 } }) }

    it { expect(connection.execute2('SQL', 'NAME')).to eq({ sql: 'SQL_A', name: 'NAME_A', binds: [], kwargs: {} }) }

    it do
      expect(
        connection.execute2('SQL', 'NAME', [:x, :y], a: 1, b: 2)
      ).to eq(
        { sql: 'SQL_A', name: 'NAME_A', binds: [:x, :y], kwargs: { a: 1, b: 2 } }
      )
    end
  end

  context 'with 2 proxies' do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use ProxyA
        config.use ProxyB
      end
      Arproxy.enable!
    end

    it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A_B', name: 'NAME_A_B', kwargs: {} }) }
  end

  context 'with 2 proxies which have an option' do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use ProxyA
        config.use ProxyB, 1
      end
      Arproxy.enable!
    end

    it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A_B1', name: 'NAME_A_B1', kwargs: {} }) }
  end

  context 'with a proxy that returns nil' do
    class ReadonlyAccess < Arproxy::Proxy
      def execute(sql, context)
        if sql =~ /^(SELECT)\b/
          super sql, context
        else
          nil
        end
      end
    end

    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use ReadonlyAccess
      end
      Arproxy.enable!
    end

    it { expect(connection.execute1('SELECT 1', 'NAME')).to eq({ sql: 'SELECT 1', name: 'NAME', kwargs: {} }) }
    it { expect(connection.execute1('UPDATE foo SET bar = 1', 'NAME')).to eq(nil) }
  end

  context 'with a legacy proxy' do
    class LegacyProxy < Arproxy::Base
      def execute(sql, name)
        super("#{sql} /* legacy_proxy */", name)
      end
    end

    before do
      Arproxy.clear_configuration
    end

    it 'raises an error' do
      expect {
        Arproxy.configure do |config|
          config.adapter = 'dummy'
          config.use LegacyProxy
        end
      }.to raise_error(Arproxy::Error, /Use `Arproxy::Proxy` instead/)
    end
  end

  context 'calls #execute with an String argument instead of `context`' do
    class WrongProxy < Arproxy::Proxy
      def execute(sql, context)
        super("#{sql} /* my_proxy */", "name=#{context.name}")
      end
    end

    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use WrongProxy
      end
      Arproxy.enable!
    end

    it do
      expect {
        connection.execute1('SQL', 'NAME')
      }.to raise_error(Arproxy::Error, /expected a `Arproxy::QueryContext`/)
    end
  end

  context do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.use ProxyA
      end
    end

    context 'enable -> disable' do
      before do
        Arproxy.enable!
        Arproxy.disable!
      end
      it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL', name: 'NAME', kwargs: {} }) }
    end

    context 'enable -> enable' do
      before do
        Arproxy.enable!
        Arproxy.enable!
      end
      it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A', name: 'NAME_A', kwargs: {} }) }
    end

    context 'enable -> disable -> disable' do
      before do
        Arproxy.enable!
        Arproxy.disable!
        Arproxy.disable!
      end
      it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL', name: 'NAME', kwargs: {} }) }
    end

    context 'clear_configuration -> enable' do
      before do
        Arproxy.clear_configuration
      end
      it do
        expect {
          Arproxy.enable!
        }.to raise_error(Arproxy::Error, /Arproxy has not been configured/)
      end
    end


    context 'enable -> disable -> enable' do
      before do
        Arproxy.enable!
        Arproxy.disable!
        Arproxy.enable!
      end
      it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A', name: 'NAME_A', kwargs: {} }) }
    end

    context 're-configure' do
      before do
        Arproxy.configure do |config|
          config.adapter = 'dummy'
          config.use ProxyB
        end
        Arproxy.enable!
      end
      it { expect(connection.execute1('SQL', 'NAME')).to eq({ sql: 'SQL_A_B', name: 'NAME_A_B', kwargs: {} }) }
    end
  end

  context 'use a plug-in' do
    before do
      Arproxy.clear_configuration
      Arproxy.configure do |config|
        config.adapter = 'dummy'
        config.plugin :test_plugin, :option_a, :option_b
      end
      Arproxy.enable!
    end

    it do
      expect(
        connection.execute1('SQL', 'NAME')
      ).to eq(
        { sql: 'SQL /* options: [:option_a, :option_b] */', name: 'NAME_PLUGIN', kwargs: {} }
      )
    end
  end

  context 'use a legacy plugin' do
    before do
      Arproxy.clear_configuration
    end

    it 'raises an error' do
      expect {
        Arproxy.configure do |config|
          config.adapter = 'dummy'
          config.plugin :legacy_plugin
        end
      }.to raise_error(Arproxy::Error, /Use `Arproxy::Proxy` instead/)
    end
  end
end
