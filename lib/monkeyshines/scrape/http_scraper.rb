require 'net/http'
module TwitterFriends
  module Scrape

    #
    # Performs the http request
    #
    # expects a global constant CONFIG containing
    # keys for CONFIG[:twitter_api][:username], CONFIG[:twitter_api][:password]
    #
    #
    #
    class HTTPScrape
      attr_accessor :http, :url, :req, :response
      def initialize url, http
        self.url  = url
        self.http = http
      end

      # create and memoize request
      def req
        @req ||= Net::HTTP::Get.new(url.to_s)
      end

      # authenticate request
      def authenticate!
        req.basic_auth CONFIG[:twitter_api][:username], CONFIG[:twitter_api][:password]
      end

      # fetch
      def get!
        return if response
        authenticate!
        self.response = http.request(req)
      end
    end

    #
    # Instantiates a persistent connection.
    # Don't know what my error-handling responsibilities are, here.
    #
    class HTTPScraper
      attr_accessor :host, :connection_opened_at
      def initialize host
        self.host = host
      end

      # Current session (starting a new one if necessary)
      def http
        return @http if (@http && @http.started?)
        self.connection_opened_at = Time.now
        # warn "Opening HTTP connection for #{host} at #{connection_opened_at}"
        @http = Net::HTTP.start(host)
      end

      # Close the current session, if any
      def finish
        @http.finish if @http
        @http = nil
      end

      # Make request, return satisfied scrape_request
      def get! scrape_request
        begin
          scrape = HTTPScrape.new(scrape_request.url, self.http)
          scrape.get!
          scrape_request.response_code     = scrape.response.code
          scrape_request.response_message  = scrape.response.message.gsub(/[\t\r\n]+/, " ")[0..60]
          scrape_request.contents          = scrape.response.body
        rescue Exception => e
          warn e
        end
        scrape_request.scraped_at        = Time.now.strftime(DATEFORMAT)
      end
    end
  end
end

