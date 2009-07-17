#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyocabinet'
module Monkeyshines
  module ScrapeStore
    class ReadThruStore < Monkeyshines::ScrapeStore::KeyStore

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
        return if db.include?(key)
        result = block.call() or return
        db.put(key, result.to_hash)
      end

    end
  end
end
