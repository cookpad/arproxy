require 'arproxy/connection_adapter_patches/base_patch'

module Arproxy
  module ConnectionAdapterPatches
    class Mysql2Patch < BasePatch
      def enable!
        if ActiveRecord.version >= '7.0'
          enable_patches :raw_execute
        else
          enable_patches :execute
        end
      end
    end
  end
end
