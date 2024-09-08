module Arproxy
  module ConnectionAdapterPatches
    SUPPORTED_ADAPTERS = %w[mysql2 postgresql]
    class PatchFactory
      def self.create(adapter_class)
        patch_class(adapter_class).new(adapter_class)
      end

      private
        def self.patch_class(adapter_class)
          adapter_name = adapter_class::ADAPTER_NAME.downcase
          if SUPPORTED_ADAPTERS.include?(adapter_name.to_s)
            require "arproxy/connection_adapter_patches/#{adapter_name}_patch"
            "Arproxy::ConnectionAdapterPatches::#{adapter_name.to_s.camelize}Patch".constantize
          else
            raise ArgumentError, "Unsupported adapter: #{adapter_name.inspect}"
          end
        end
    end
  end
end
