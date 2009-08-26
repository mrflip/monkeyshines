require 'active_support/core_ext/class/inheritable_attributes'
require 'time'
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
        warn 'nil response' unless response
        acknowledge(response, page)
        break if is_last?(response, page)
      end
      finish_pagination!
    end

    # Set up bookkeeping for pagination tracking
    def begin_pagination!
    end

    # Finalize bookkeeping at conclusion of scrape_job.
    def finish_pagination!
    end

    #
    # Feed back info from the scrape
    #
    def acknowledge response, page
    end

    # return true if the next request would be pointless (true if, perhaps, the
    # response had no items, or the API page limit is reached)
    def is_last? response, page
      ( (page >= max_pages) ||
        (response && response.healthy? && (response.num_items < items_per_page)) )
    end

    #
    # Soft limit on the number of pages to scrape.
    #
    # Typically, leave this set to the hard_request_limit if you don't know
    # beforehand how many pages to scrape, and override is_last? to decide when
    # to stop short of the API limit
    #
    def max_pages
      hard_request_limit
    end

    # inject class variables
    def self.included base
      base.class_eval do
        # Hard request limit: do not in any case exceed this number of requests
        class_inheritable_accessor :hard_request_limit
        # max items per page, from API
        class_inheritable_accessor :items_per_page
        #
        # Span of items gathered in this scrape scrape_job.
        attr_accessor :sess_items, :sess_span, :sess_timespan
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

    # #
    # # Threshold count-per-page and actual count to get number of expected pages.
    # # Cap the request with max
    # def pages_from_count per_page, count, max=nil
    #   num = [ (count.to_f / per_page.to_f).ceil, 0 ].max
    #   [num, max].compact.min
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

    #
    # Return true if the next request would be pointless (true if, perhaps, the
    # response had no items, or the API page limit is reached)
    def is_last? response, page
      unscraped_span.empty? || super(response, page)
    end

    # Set up bookkeeping for pagination tracking
    def begin_pagination!
      self.sess_items    ||= 0
      self.sess_span       = UnionInterval.new
      self.sess_timespan   = UnionInterval.new
      super
    end

    def finish_pagination!
      # piw = [(prev_items.to_f ** 0.66), (items_per_page * hard_request_limit * 4.0)].min
      # puts ([Time.now.strftime("%M:%S"), "%-23s"%query_term] + [prev_rate, sess_rate, avg_rate, sess_timespan.size.to_f, prev_items, sess_items, piw, (1000/avg_rate)].map{|s| "%15.4f"%(s||0) }).join("\t") rescue nil
      self.prev_rate     = avg_rate
      if sess_items == (hard_request_limit * items_per_page)
        # bump the rate if we hit the hard cap:
        new_rate = [prev_rate * 1.25, 1000/120.0].max
        Log.info "Bumping rate on #{query_term} from #{prev_rate} to #{new_rate}"
        self.prev_rate = new_rate
      end
      self.prev_items    = prev_items.to_i + sess_items.to_i
      self.prev_span     = sess_span + prev_span
      self.new_items     = sess_items.to_i + new_items.to_i
      self.sess_items    = 0
      self.sess_span     = UnionInterval.new
      self.sess_timespan = UnionInterval.new
      super
    end

    #
    # Feed back info from the scrape
    #
    def acknowledge response, page
      super response, page
      return unless response && response.items
      count_new_items response
      update_spans response
    end

    # account for additional items
    def count_new_items response
      num_items = response.num_items
      # if there was overlap with a previous scrape, we have to count the items by hand
      prev_span = self.prev_span
      if prev_span.max && response.span && (response.span.min < prev_span.max)
        num_items = response.items.inject(0){|n,item| (prev_span.include? item['id']) ? n : n+1 }
      end
      self.sess_items += num_items
    end

    def update_spans response
      # Update intervals
      self.sess_span     << response.span
      self.sess_timespan << response.timespan
    end


    def sess_rate
      return nil if (!sess_timespan) || (sess_timespan.size == 0)
      sess_items.to_f / sess_timespan.size.to_f
    end
    #
    # How often an item rolls in, on average
    #
    def avg_rate
      return nil if (sess_items.to_f == 0 && (prev_rate.blank? || prev_items.to_f == 0))
      prev_weight = prev_items.to_f ** 0.66
      sess_weight = sess_items.to_f
      prev_weight = [prev_weight, sess_weight*3].min if sess_weight > 0
      weighted_sum = (
        (prev_rate.to_f * prev_weight) + # damped previous avg
        (sess_rate.to_f * sess_weight) ) # current avg
      rt = weighted_sum / (prev_weight + sess_weight)
      rt
    end

    # gap between oldest scraped in this scrape_job and last one scraped in
    # previous scrape_job.
    def unscraped_span
      UnionInterval.new(prev_span_max, sess_span.min)
    end
    # span of previous scrape
    def prev_span
      @prev_span ||= UnionInterval.new(prev_span_min, prev_span_max)
    end
    def prev_span= min_max
      self.prev_span_min, self.prev_span_max = min_max.to_a
      @prev_span = UnionInterval.new(prev_span_min, prev_span_max)
    end

    # inject class variables
    def self.included base
      base.class_eval do
        attr_accessor :new_items
        # include Monkeyshines::Paginated
      end
    end
  end

end
