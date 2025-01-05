require_relative './spec_helper'
require 'arproxy/proxy_chain_head'
require 'arproxy/proxy_chain_tail'
require 'arproxy/proxy'

describe Arproxy::Proxy do
  it do
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
    head = Arproxy::ProxyChainHead.new
    head.next_proxy = p1

    conn = DummyConnectionAdapter.new
    expect(head.execute_head_with_binds(conn, 'execute', 'SELECT 1', 'test', [1])).to eq('SELECT 1 /* Proxy1 */ /* Proxy2 */')
  end
end
