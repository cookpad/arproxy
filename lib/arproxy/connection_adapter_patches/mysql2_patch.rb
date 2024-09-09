require 'arproxy/connection_adapter_patches/base_patch'

module Arproxy
  module ConnectionAdapterPatches
    class Mysql2Patch < BasePatch
      def enable!
        enable_patches :raw_execute
      end
    end
  end
end
