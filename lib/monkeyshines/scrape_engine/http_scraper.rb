require 'net/http'
module Monkeyshines
  module ScrapeEngine

    #
    # Instantiates a persistent connection.
    #
    class HttpScraper
      # Default user agent presented to servers
      USER_AGENT = "Monkeyshines v0.1"
      attr_accessor :host, :connection_opened_at, :username, :password, :http_get_options

      def initialize host, options={}
        self.host = host
        self.username = options[:username]
        self.password = options[:password]
        self.http_get_options = {}
        self.http_get_options["User-Agent"] = options[:user_agent] || USER_AGENT
      end

      # Current session (starting a new one if necessary)
      def http
        # Don't know what my error-handling responsibilities are, here.
        return @http if (@http && @http.started?)
        self.connection_opened_at = Time.now
        warn "Opening HTTP connection for #{host} at #{connection_opened_at}"
        @http = Net::HTTP.start(host)
      end

      # Close the current session, if any
      def finish
        @http.finish if @http
        @http = nil
      end

      # Build and dispatch request
      def perform_request url
        req = Net::HTTP::Get.new(url.to_s, http_get_options)
        authenticate req
        http.request req
      end

      # authenticate request
      def authenticate req
        req.basic_auth(username, password) if username && password
      end

      # Make request, return satisfied scrape_request
      def get scrape_request
        begin
          response = perform_request scrape_request.url
          scrape_request.response_code     = response.code
          scrape_request.response_message  = response.message.gsub(/[\t\r\n]+/, " ")[0..60]
          scrape_request.contents          = response.body
        rescue Exception => e
          warn e
        end
        scrape_request.scraped_at = Time.now.utc.to_flat
        scrape_request
      end
    end
  end

end
