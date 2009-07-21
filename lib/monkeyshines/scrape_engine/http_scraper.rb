require 'net/http'
module Monkeyshines
  module ScrapeEngine

    #
    # Opens a persistent connection and makes repeated requests.
    #
    # * authentication
    # * backoff and logging on client or server errors
    #
    class HttpScraper
      # Default user agent presented to servers
      USER_AGENT = "Monkeyshines v0.1"
      attr_accessor :connection_opened_at, :username, :password, :http_req_options, :options

      def initialize options={}
        self.options  = options
        self.username = options[:username]
        self.password = options[:password]
        self.http_req_options = {}
        self.http_req_options["User-Agent"] = options[:user_agent] || USER_AGENT
      end

      #
      # Current session (starting a new one if necessary)
      # If the host has changed, closes old conxn and opens new one
      #
      def http host, port=nil
        return @http if (@http && (@http.started?) && (@host == host))
        close        if (@http && (@http.started?) && (@host != host))
        @host = host
        @connection_opened_at = Time.now
        Monkeyshines.logger.info "Opening HTTP connection for #{@host} at #{@connection_opened_at}"
        @http = Net::HTTP.new(@host)
        @http.set_debug_output($stderr) if options[:debug_requests]
        @http.start
      end

      # Close the current session, if any
      def close
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

      #
      # Based on the response code, sleep (in case servers are overheating) and
      # log response.
      #
      def backoff response
        sleep_time = 0
        case response
        when Net::HTTPSuccess             then return         # 2xx
        when Net::HTTPRedirection         then return         # 3xx
        when Net::HTTPBadRequest          then sleep_time = 5 # 400 (rate limit, probably)
        when Net::HTTPUnauthorized        then sleep_time = 0 # 401 (protected user, probably)
        when Net::HTTPForbidden           then sleep_time = 4 # 403 update limit
        when Net::HTTPNotFound            then sleep_time = 0 # 404 deleted
        when Net::HTTPServiceUnavailable  then sleep_time = 4 # 503 Fail Whale
        when Net::HTTPServerError         then sleep_time = 2 # 5xx All other server errors
        else                              sleep_time = 1
        end
        Monkeyshines.logger.warn "Received #{response.code}, sleeping #{sleep_time} ('#{response.message[0..200].gsub(%r{[\r\n\t]}, " ")}' from #{@host}+#{@connection_opened_at})"
        sleep sleep_time
      end

      # Make request, return satisfied scrape_request
      def get scrape_request
        begin
          response = perform_request(scrape_request.url)
          scrape_request.response_code    = response.code
          scrape_request.response_message = response.message[0..200].gsub(/[\n\r\t]+/, ' ')
          scrape_request.response         = response
          backoff response
        rescue StandardError, Timeout::Error => e
          warn [e.to_s, scrape_request.to_s[0..2000].gsub(/[\n\r\t]+/, ' ')].join("\t")
          close # restart the connection
        rescue Exception => e
          Monkeyshines.logger.warn e
          raise e
        end
        scrape_request.scraped_at = Time.now.utc.to_flat
        scrape_request
      end

      def get_and_report_timing *args
        start = Time.now.to_f
        response = get *args
        Monkeyshines.logger.info( Time.now.to_f - start )
        response
      end
    end

  end
end
