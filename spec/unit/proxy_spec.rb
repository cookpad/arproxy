require_relative './spec_helper'
require 'arproxy/proxy_chain_tail'
require 'arproxy/proxy'
require 'arproxy/query_context'

describe Arproxy::Proxy do
  before(:all) do
    class DummyConnectionAdapter
      def execute(sql, name = nil, binds = [], **kwargs)
        "#{sql}"
      end
    end

    class Proxy1 < Arproxy::Proxy
      def execute(sql, context)
        super("#{sql} /* Proxy1 */", context)
      end
    end

    class Proxy2 < Arproxy::Proxy
      def execute(sql, context)
        super("#{sql} /* Proxy2 */", context)
      end
    end

    tail = Arproxy::ProxyChainTail.new
    p2 = Proxy2.new
    p2.next_proxy = tail
    p1 = Proxy1.new
    p1.next_proxy = p2
    @head = p1

    @conn = DummyConnectionAdapter.new
  end

  context 'with binds' do
    let(:context) { Arproxy::QueryContext.new(raw_connection: @conn, execute_method_name: 'execute', with_binds: true, name: 'test', binds: [1]) }
    describe '#execute' do
      it do
        expect(@head.execute('SELECT 1', context)).to eq('SELECT 1 /* Proxy1 */ /* Proxy2 */')
      end
    end
  end

  context 'without binds' do
    let(:context) { Arproxy::QueryContext.new(raw_connection: @conn, execute_method_name: 'execute', with_binds: false, name: 'test') }
    describe '#execute' do
      it do
        expect(@head.execute('SELECT 1', context)).to eq('SELECT 1 /* Proxy1 */ /* Proxy2 */')
      end
    end
  end
end
