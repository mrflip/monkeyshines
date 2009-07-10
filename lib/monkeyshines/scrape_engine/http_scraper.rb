require 'net/http'
module Monkeyshines
  module ScrapeEngine

    #
    # Instantiates a persistent connection.
    #
    class HttpScraper
      # Default user agent presented to servers
      USER_AGENT = "Monkeyshines v0.1"
      attr_accessor :connection_opened_at, :username, :password, :http_req_options

      def initialize options={}
        self.username = options[:username]
        self.password = options[:password]
        self.http_req_options = {}
        self.http_req_options["User-Agent"] = options[:user_agent] || USER_AGENT
      end

      # Current session (starting a new one if necessary)
      def http host, port=nil
        return @http if (@http && (@http.started?) && (@host == host))
        finish       if (@http && (@http.started?) && (@host != host))
        @host = host
        @connection_opened_at = Time.now
        Monkeyshines.logger.info "Opening HTTP connection for #{@host} at #{@connection_opened_at}"
        @http = Net::HTTP.new(@host)
        @http.set_debug_output $stderr
        @http.start
      end

      # Close the current session, if any
      def finish
        Monkeyshines.logger.info "Closing HTTP connection for #{@host} from #{@connection_opened_at}"
        @http.finish if @http
        @http = nil
      end

      # Build and dispatch request
      def perform_request url_str
        url = URI.parse(url_str)
        req = Net::HTTP::Get.new(url.send(:path_query), http_req_options)
        authenticate req
        http(url.host, url.port).request req
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
          scrape_request.response          = response
        rescue Exception => e
          warn e
        end
        scrape_request.scraped_at = Time.now.utc.to_flat
        scrape_request
      end
    end
  end

end
