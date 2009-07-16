require 'active_support/core_ext/class/inheritable_attributes'
module Monkeyshines

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
    #
    # Generates request for each page to be scraped
    # result of block is passed to #acknowledge
    # scraping stops after max_requests requests or when is_last?(response, page)
    #
    def each_page pageinfo={}, &block
      (1..max_pages).each do |page|
        response = yield make_request(page, pageinfo)
        acknowledge response
        hsh = response.parsed_contents.dup ; hsh.delete('results')
        p [response.num_items, scrape_id_span, scrape_time_span, hsh, response.url, ]
        break if is_last?(response, page)
      end
    end

    # return true if the next request would be pointless (true if, perhaps, the
    # response had no items, or the API page limit is reached)
    def is_last? response, page
      ( (page >= max_pages) ||
        (response && response.healthy? && (response.num_items < items_per_page)) ||
        (unscraped_id_span.empty?)
        )
    end

    def unscraped_id_span
      UnionInterval.new(prev_id_span.max, scrape_id_span.min)
    end

    def begin_pagination!
      self.num_items ||= 0
      self.scrape_id_span   ||= UnionInterval.new
      self.scrape_time_span ||= UnionInterval.new
      self.prev_id_span     ||= UnionInterval.new
      self.prev_time_span   ||= UnionInterval.new
    end

    #
    # Feed back info from the scrape
    #
    def acknowledge response
      return unless response && response.items
      self.num_items        += response.num_items
      self.scrape_id_span   << response.id_span
      self.scrape_time_span << response.time_span
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

    # How often an item rolls in, on average
    def avg_item_rate
      total_items / (last_item_at - first_item_at)
    end
    # How many items we expect to have accumulated since the last scrape.
    def items_since_last_scrape
      time_since_last_scrape = Time.now.utc - last_scraped_at
      items_rate * time_since_last_scrape
    end

    # def pages
    #   ( items_since_last_scrape / items_per_page ).clamp(0, max_pages)
    # end


    # inject class variables
    def self.included base
      base.class_eval do
        class_inheritable_accessor :items_per_page, :max_pages
        attr_accessor :scrape_id_span, :scrape_time_span
        attr_accessor :prev_id_span,   :prev_time_span
        attr_accessor :num_items
      end
    end
  end




  # #
  # #
  # module PaginatedSimply
  #   def max_pages
  #     mp = fudge_factor * (n_items - prev_scraped_items) / items_per_page
  #     return 0 if mp == 0
  #     (mp+1).clamp(1, max_pages).to_i
  #   end
  #
  #   def begin_pagination!
  #     self.num_items ||= 0
  #     self.scrape_id_span   ||= UnionInterval.new
  #     self.prev_id_span     ||= UnionInterval.new
  #   end
  #
  #   #
  #   # Feed back info from the scrape
  #   #
  #   def acknowledge response
  #     return unless response && response.items
  #     self.num_items        += response.num_items
  #     self.scrape_id_span   << response.id_span
  #     self.scrape_time_span << response.time_span
  #   end
  #
  #   # How often an item rolls in, on average
  #   def avg_item_rate
  #     total_items / (last_item_at - first_item_at)
  #   end
  #   # How many items we expect to have accumulated since the last scrape.
  #   def items_since_last_scrape
  #     time_since_last_scrape = Time.now.utc - last_scraped_at
  #     items_rate * time_since_last_scrape
  #   end
  #
  #
  #   # inject class variables
  #   def self.included base
  #     base.class_eval do
  #       class_inheritable_accessor :items_per_page, :max_pages
  #       attr_accessor :scrape_id_span, :scrape_time_span
  #       attr_accessor :prev_id_span,   :prev_time_span
  #       attr_accessor :num_items
  #     end
  #   end
  # end

end
