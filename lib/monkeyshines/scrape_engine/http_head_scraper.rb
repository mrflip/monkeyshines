require 'monkeyshines/scrape_engine/http_scraper'
module Monkeyshines
  module ScrapeEngine
    class HttpHeadScraper < HttpScraper

      # #
      # # Get the redirect location... don't follow it, just request and store it.
      # #
      # def fetch_dest_url! options={ }
      #   return unless dest_url.blank? && scraped_at.blank?
      #   options = options.reverse_merge :sleep => 1
      #   fix_src_url!
      #   begin
      #     # look for the redirect
      #     raw_dest_url = Net::HTTP.get_response(URI.parse(src_url))["location"]
      #     self.dest_url = self.class.scrub_url(raw_dest_url)
      #     sleep options[:sleep]
      #   rescue Exception => e
      #     nil
      #   end
      #   self.scraped_at = TwitterFriends::StructModel::ModelCommon.flatten_date(DateTime.now) if self.scraped_at.blank?
      # end

      # Build and dispatch request
      def perform_request url_str
        url = URI.parse(url_str)
        req = Net::HTTP::Head.new(url.send(:path_query), http_req_options)
        authenticate req
        http(url.host, url.port).request req
      end

    end
  end
end
