#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyocabinet'
module Monkeyshines
  module ScrapeStore
    class ReadThruStore < Monkeyshines::ScrapeStore::TyrantTdbKeyStore

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
        return if db.has_key?(key)
        result = block.call() or return
        super(key, result)
      end

      def force_set key, val
        super.set(key, result)
      end

    end
  end
end
