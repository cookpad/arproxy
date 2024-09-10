require 'arproxy/connection_adapter_patches/base_patch'

module Arproxy
  module ConnectionAdapterPatches
    class Sqlite3Patch < BasePatch
      def enable!
        if ActiveRecord.version >= '7.1'
          enable_patches :raw_execute, :internal_exec_query
        else
          enable_patches :execute, :exec_query
        end
      end
    end
  end
end
