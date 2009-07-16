require 'active_support/core_ext/class/inheritable_attributes'
module Monkeyshines
  #
  # Paginated lets you make repeated requests to collect a timeline or
  # collection of items.
  #
  # You will typically want to set the
  #
  # A Paginated-compatible ScrapeRequest should inherit from or be compatible
  # with +Monkeyshines::ScrapeRequest+ and additionally define
  # * [#items]  list of individual items in the response; +nil+ if there was an
  #   error, +[]+ if the response was well-formed but returned no items.
  # * [#num_items] number of items from this response
  # * [#span] the range of (typically) IDs within this scrape. Used to know when
  #   we've reached results from previous session
  #
  #
  module Paginated
    #
    # Generates request for each page to be scraped
    #
    # Block must return the fulfilled scrape_request response.  This response is
    # passed to +#acknowledge+ for bookkeeping, then the next request is
    # made.
    #
    # Scraping stops after max_pages requests or when is_last?(response, page)
    #
    def each_request pageinfo={}, &block
      begin_pagination!
      (1..hard_request_limit).each do |page|
        response = yield make_request(page, pageinfo)
        acknowledge response
        break if is_last?(response, page)
      end
      finish_pagination!
    end

    # Set up bookkeeping for pagination tracking
    def begin_pagination!
      puts "Paginated begin_pagination!"
    end

    # Finalize bookkeeping at conclusion of session.
    def finish_pagination!
    end

    #
    # Feed back info from the scrape
    #
    def acknowledge response
    end

    # return true if the next request would be pointless (true if, perhaps, the
    # response had no items, or the API page limit is reached)
    def is_last? response, page
      ( (page >= max_pages) ||
        (response && response.healthy? && (response.num_items < items_per_page)) )
    end

    # Soft limit on the number of pages to scrape.
    #
    # Typically, leave this set to the hard_request_limit if you don't know
    # beforehand how many pages to scrape, and override is_last? to decide when
    # to stop short of the API limit
    #
    def max_pages
      hard_request_limit
    end

    #
    # How often an item rolls in, on average
    #
    def items_rate interval
      num_items.to_f / interval.size.to_f
    end

    #
    # How many items we expect to have accumulated since the last scrape.
    #
    def items_since_last_scrape
      time_since_last_scrape = Time.now.utc - prev_timespan.max
      items_rate(prev_timespan) * time_since_last_scrape
    end

    # inject class variables
    def self.included base
      base.class_eval do
        # Hard request limit: do not in any case exceed this number of requests
        class_inheritable_accessor :hard_request_limit
        # Span of items gathered in this scrape session.
        attr_accessor :sess_span, :sess_timespan
        # Values from the previous scrape session
        attr_accessor :prev_span,   :prev_timespan
        # max items per page, from API
        class_inheritable_accessor :items_per_page
        # Number of items collected in this and previous sessions.
        attr_accessor :num_items
      end
    end
  end

  module PaginatedTimeline
    # Soft limit on the number of pages to scrape.
    #
    # Typically, leave this set to the hard_request_limit if you don't know
    # beforehand how many pages to scrape, and override is_last? to decide when
    # to stop short of the API limit
    #
    def max_pages
      mp = fudge_factor * (n_items - prev_scraped_items) / items_per_page
      return 0 if mp == 0
      (mp+1).clamp(1, hard_request_limit).to_i
    end
    # inject class variables
    def self.included base
      base.class_eval do
        include Monkeyshines::Paginated
      end
    end
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

    #
    # Return true if the next request would be pointless (true if, perhaps, the
    # response had no items, or the API page limit is reached)
    def is_last? response, page
      unscraped_span.empty? || super(response, page)
    end

    # Set up bookkeeping for pagination tracking
    def begin_pagination!
      puts "PaginatedWithLimit begin_pagination!"
      self.num_items     ||= 0
      self.sess_span     ||= UnionInterval.new
      self.sess_timespan ||= UnionInterval.new
      self.prev_span     ||= UnionInterval.new
      self.prev_timespan ||= UnionInterval.new
      super
    end

    def finish_pagination!
      self.prev_timespan << sess_timespan
      self.prev_span     << sess_span
      super
    end

    #
    # Feed back info from the scrape
    #
    def acknowledge response
      return unless response && response.items
      self.num_items     += response.num_items
      self.sess_span     << response.span
      self.sess_timespan << response.timespan
      super
    end

    # gap between oldest scraped in this session and last one scraped in
    # previous session.
    def unscraped_span
      UnionInterval.new(prev_span.max, sess_span.min)
    end

    # MIN_RESCHED_INTERVAL = 60*1
    # MAX_RESCHED_INTERVAL = 60*60*24
    #
    # def rescheduled
    #   req = self.dup
    #   req.min_id         = last_item_id
    #   req.min_time       = last_item_at
    #   next_sess_in     = (0.8 * items_per_page) / avg_items_rate
    #   req.next_scrape_at = last_item_at + next_scrape_in.clamp(MIN_RESCHED_INTERVAL, MAX_RESCHED_INTERVAL)
    #   req
    # end

    # inject class variables
    def self.included base
      base.class_eval do
        # include Monkeyshines::Paginated
      end
    end
  end

end
