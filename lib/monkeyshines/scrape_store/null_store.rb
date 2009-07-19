module Monkeyshines
  module ScrapeStore
    class NullStore < Monkeyshines::ScrapeStore::Base

      def each *args, &block
      end


      # Does nothing!
      def set *args
      end

    end
  end
end
