module Monkeyshines
  module ScrapeRequest

    module Paginated
      def is_last? result, page
        ( (curr_page     > max_pages) )
      end

      def each_page *pageinfo, &block
        (1..pages).each do |page|
          yield make_request(template_request, page, *pageinfo)
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
    #
    # The first
    #
    #    req?min_id=1234&max_id=
    #    => [ [8675, ...], ..., [8012, ...] ] # 100 results
    #    req?min_id=1234&max_id=8011
    #    => [ [7581, ...], ..., [2044, ...] ] # 100 results
    #    req?min_id=1234&max_id=2043
    #    => [ [2012, ...], ..., [1234, ...] ] #  69 results
    #
    # * The search terminates when
    # ** max_requests requests have been made, or
    # ** the limit params interval is zero,    or
    # ** a successful result with fewer than rsrc_per_page is received.
    #
    # * You will want to save <req?min_id=8676&max_id=""> for later scrape
    #
    module PaginatedWithLimit
      def is_last? result, page
        ( (curr_page     > max_pages)     ||
          (result.length < rsrc_per_page))
      end

      def update_limit_param result
        self.max_id = result.last['id']
      end

      def each_page *pageinfo, &block
        (1..pages).each do |page|
          # get results
          result = yield make_request(template_request, page, *pageinfo)
          # save the
          new_lower_limit ||= result.upper_limit
          #
          update_limit_param result
          #
          break if is_last?(result, page)
        end
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
