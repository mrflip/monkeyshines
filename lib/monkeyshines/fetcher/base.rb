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
      attr_accessor :options
      #
      # Options hash configures any subclass behavior
      #
      def initialize _options={}
        self.options = _options
      end

      # Make request, return satisfied scrape_request
      def get scrape_request
      end

      # inscribes request with credentials
      def authenticate req
      end

      # Based on the response code, sleep (in case servers are overheating) and
      # log response.
      def backoff response
        sleep
      end

      # A compact timestamp, created each time it's called
      def self.timestamp
        Time.now.utc.to_flat
      end

      # Release any persistent connections to the remote server
      def close
      end
    end
  end
end
