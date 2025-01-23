module Arproxy
  class QueryContext
    attr_accessor :raw_connection, :execute_method_name, :with_binds, :name, :binds, :kwargs

    def initialize(raw_connection:, execute_method_name:, with_binds:, name: nil, binds: [], kwargs: {})
      @raw_connection = raw_connection
      @execute_method_name = execute_method_name
      @with_binds = with_binds
      @name = name
      @binds = binds
      @kwargs = kwargs
    end

    def with_binds?
      !!@with_binds
    end
  end
end
