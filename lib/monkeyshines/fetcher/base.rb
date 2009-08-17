module Monkeyshines
  module Fetcher
    #
    # Base URL fetcher.
    #
    # Subclasses must provide
    #   get(scrape_request)
    # returning the same scrape_request with its contents, scraped_at and
    # response fields appropriately filled in.
    #
    class Base
      def initialize options={}
      end

      def close
      end
    end
  end
end
