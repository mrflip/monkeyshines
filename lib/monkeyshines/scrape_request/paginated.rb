module Monkeyshines
  module ScrapeRequest

    module Paginated
      def is_last? response, page
        ( (curr_page     > max_pages) )
      end

      def each_page *pageinfo, &block
        (1..pages).each do |page|
          yield make_request(template_request, page, *pageinfo)
        end
      end

      # How often an item rolls in, on average
      def avg_item_rate
        total_items / (last_item_at - first_item_at)
      end

      MIN_RESCHED_INTERVAL = 60*1
      MAX_RESCHED_INTERVAL = 60*60*24
      def rescheduled
        req = self.dup
        req.min_id         = last_item_id
        req.min_time       = last_item_at
        next_scrape_in     = (0.8 * items_per_page) / avg_items_rate
        req.next_scrape_at = last_item_at + next_scrape_in.clamp(MIN_RESCHED_INTERVAL, MAX_RESCHED_INTERVAL)
        req
      end

      def self.included base
        base.class_eval do
          cattr_accessor :num_per_page, :max_pages
        end
      end
    end

    module PaginatedByVelocity
      def items_since_last_scrape
        time_since_last_scrape = Time.now.utc - last_scraped_at
        items_rate * time_since_last_scrape
      end

      def pages
        ( items_since_last_scrape / items_per_page ).clamp(0, max_pages)
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
    #   items_per_page
    #
    #
    # The first
    #
    #    req?min_id=1234&max_id=
    #    => [ [8675, ...], ..., [8012, ...] ] # 100 items
    #    req?min_id=1234&max_id=8011
    #    => [ [7581, ...], ..., [2044, ...] ] # 100 items
    #    req?min_id=1234&max_id=2043
    #    => [ [2012, ...], ..., [1234, ...] ] #  69 items
    #
    # * The search terminates when
    # ** max_requests requests have been made, or
    # ** the limit params interval is zero,    or
    # ** a successful response with fewer than items_per_page is received.
    #
    # * You will want to save <req?min_id=8676&max_id=""> for later scrape
    #
    module PaginatedWithLimit
      def is_last? response, page
        ( (curr_page     > max_pages)     ||
          (response.length < items_per_page))
      end

      def update_limit_param response
        self.max_id = response.last['id']
      end

      def each_page *pageinfo, &block
        (1..pages).each do |page|
          # get responses
          response = yield make_request(template_request, page, *pageinfo)
          # save the
          new_lower_limit ||= response.upper_limit
          # s
          update_limit_param response
          #
          break if is_last?(response, page)
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
