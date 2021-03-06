require 'monkeyshines/fetcher/http_fetcher'
module Monkeyshines
  module Fetcher
    #
    # Requests the HEAD only, for cases where you don't need to know actual page
    # contents (e.g. you're looking for server info or scraping URL shorteners)
    #
    class HttpHeadFetcher < HttpFetcher

      #
      # Build and dispatch request
      # We do a HEAD request only, no reason to get the body.
      #
      def perform_request url_str
        url = URI.parse(url_str)
        req = Net::HTTP::Head.new(url.send(:path_query), http_req_options)
        authenticate req
        http(url.host, url.port).request req
      end

    end
  end
end
