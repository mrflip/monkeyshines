module Monkeyshines
  module ScrapeStore
    class ReadThroughStore
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :store

      def initialize store
        self.store = store
      end

      #
      # If key is absent, save the result of calling the block.
      # If key is present, block is never called.
      #
      # Ex:
      #   rt_store.set(url) do
      #     scraper.get url # will only be called if url isn't in rt_store
      #   end
      #
      def set key, &block
        if val = store.get(key)
          return val
        else
          store.set block.call()
        end
      end
    end
  end
end
