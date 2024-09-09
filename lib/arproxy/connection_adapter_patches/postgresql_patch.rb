require 'arproxy/connection_adapter_patches/base_patch'

module Arproxy
  module ConnectionAdapterPatches
    class PostgresqlPatch < BasePatch
      def enable!
        enable_patches :raw_execute, :internal_exec_query
      end
    end
  end
end
