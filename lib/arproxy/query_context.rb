module Arproxy
  class QueryContext
    attr_accessor :execute_method_name, :with_binds, :name, :binds, :kwargs

    def initialize(execute_method_name:, with_binds:, name: nil, binds: [], kwargs: {})
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
