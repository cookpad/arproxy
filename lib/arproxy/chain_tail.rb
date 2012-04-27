module Arproxy
  class ChainTail
    def execute(connection, sql, name=nil)
      connection.execute_without_arproxy(sql, name)
    end
  end
end
