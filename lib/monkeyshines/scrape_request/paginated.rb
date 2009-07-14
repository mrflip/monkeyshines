module Monkeyshines
  module ScrapeRequest

    module Paginated
      def requests
        (1..pages).each do
          make_request template_request
        end
      end

      def self.included base
        base.class_eval do
          cattr_accessor :num_per_page, :max_pages
        end
      end
    end

    module PaginatedByVelocity
      def rsrc_since_last_scrape
        time_since_last_scrape = Time.now.utc - last_scraped_at
        rsrc_rate * time_since_last_scrape
      end

      def pages
        ( rsrc_since_last_scrape / rsrc_per_page ).clamp(0, max_pages)
      end

      # def self.included base
      #   base.class_eval do
      #   end
      # end
    end

    #
    # Scenario: you request paginated search requests with a limit parameter (a
    # max_id or min_id, for example).
    #
    # * request successive pages,
    # * use info on the requested page to set the next limit parameter
    # * stop when max_pages is reached or a successful request gives fewer than
    #   rsrc_per_page
    #
    module PaginatedWithLimit
      def rsrc_since_last_scrape
        time_since_last_scrape = Time.now.utc - last_scraped_at
        rsrc_rate * time_since_last_scrape
      end


      def is_last result
        # num_results =
        num < rsrc_per_page
      end

      def requests &block
        max_pages.times do
          result = yield make_request(template_request)
          update_params_from result
          break if is_last(result)
        end
      end

      def pages
        ( rsrc_since_last_scrape / rsrc_per_page ).clamp(0, max_pages)
      end

    end

  end
end

class Numeric
  def clamp min, max
    return min if self <= min
    return max if self >= max
    self
  end
end
