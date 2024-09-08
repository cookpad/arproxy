module Arproxy
  module ConnectionAdapterPatches
    class BasePatch
      attr_reader :adapter_class

      def initialize(adapter_class)
        @adapter_class = adapter_class
      end

      def enable!
        raise NotImplementedError
      end

      def disable!
        raise NotImplementedError
      end
    end
  end
end
