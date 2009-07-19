module Monkeyshines
  module ScrapeStore
    class ConditionalStore < Monkeyshines::ScrapeStore::Base
      attr_accessor :cache, :store, :misses

      #
      #
      # +cache+ must behave like a hash (Hash and
      #  Monkeyshines::ScrapeStore::TyrantHdbKeyStore are both cromulent
      #  choices).
      #
      #
      #
      def initialize cache, store
        self.cache  = cache
        self.store  = store
        self.misses = 0
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
      def set key, force=nil, &block
        return if (!force) && cache.include?(key)
        cache_val, store_val = block.call()
        return unless cache_val
        cache.set_nr key, cache_val # update cache
        store << store_val          # save value
        self.misses += 1                 # track the cache miss
      end

      def size
        cache.size
      end
    end
  end
end
