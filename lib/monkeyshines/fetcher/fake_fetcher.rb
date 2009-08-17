module Monkeyshines
  module Fetcher
    FakeResponse = Struct.new(:code, :message, :body)

    class FakeFetcher < Base

      # Fake a satisfied scrape_request
      def get scrape_request
        response = FakeResponse.new('200', 'OK', { :fetched => scrape_request.url }.to_json )
        scrape_request.response_code    = response.code
        scrape_request.response_message = response.message
        scrape_request.response         = response
        scrape_request.scraped_at       = Time.now.utc.to_flat
        scrape_request
      end

    end
  end
end
