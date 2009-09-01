require 'time'
require 'monkeyshines/utils/union_interval'
module Monkeyshines
  module ScrapeRequestCore

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
      # Soft limit on the number of pages to scrape.
      #
      # If we know the max_total_items, use it to set the number of pages;
      # otherwise, let it run up to the hard limit.
      #
      # Typically, use this to set an upper limit that you know beforehand, and
      # use #is_last? to decide based on the results
      #
      def max_pages
        return hard_request_limit if (!max_total_items)
        (max_total_items.to_f / max_items).ceil.clamp(0, hard_request_limit)
      end

      # Number of items returned in this request
      def num_items()
        items ? items.length : 0
      end

      # inject class variables
      def self.included base
        base.class_eval do
          # Hard request limit: do not in any case exceed this number of requests
          class_inheritable_accessor :hard_request_limit

          # max items per page the API might return
          class_inheritable_accessor :max_items

          # Total items in all requests, if known ahead of time -- eg. a
          # twitter_user's statuses_count can be used to set the max_total_items
          # for TwitterUserTimelineRequests
          attr_accessor :max_total_items
        end
      end
    end # Paginated

    module Paginating
      #
      # Generates request for each page to be scraped.
      #
      # The job class must define a #request_for_page(page) method.
      #
      # * request is generated
      # * ... and yielded to the call block. (which must return the fulfilled
      #   scrape_request response.)
      # * after_fetch method chain invoked
      #
      # Scraping stops when is_last?(response, page) is true
      #
      def each_request info=nil, &block
        before_pagination()
        (1..hard_request_limit).each do |page|
          request  = request_for_page(page, info)
          response = yield request
          after_fetch(response, page)
          break if is_last?(response, page)
        end
        after_pagination()
      end

      # return true if the next request would be pointless (true if, perhaps, the
      # response had no items, or the API page limit is reached)
      def is_last? response, page
        ( (page >= response.max_pages) ||
          (response && response.healthy? && (response.num_items < response.max_items)) )
      end

      # Bookkeeping/setup preceding pagination
      def before_pagination
      end

      # Finalize bookkeeping at conclusion of scrape_job.
      def after_pagination
      end

      # Feed back info from the fetch
      def after_fetch response, page
      end

      # inject class variables
      def self.included base
        base.class_eval do
          # Hard request limit: do not in any case exceed this number of requests
          class_inheritable_accessor :hard_request_limit
        end
      end
    end # Paginating

    #
    # Scenario: you request paginated search requests with a limit parameter (a
    # max_id or min_id, for example).
    #
    # * request successive pages,
    # * use info on the requested page to set the next limit parameter
    # * stop when max_pages is reached or a successful request gives fewer than
    #   max_items
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
    # ** a successful response with fewer than max_items is received.
    #
    # * You will want to save <req?min_id=8676&max_id=""> for later scrape
    #
    module PaginatedWithLimit
      # Set up bookkeeping for pagination tracking
      def before_pagination
        self.started_at      = Time.now.utc
        self.sess_span       = UnionInterval.new
        self.sess_timespan   = UnionInterval.new
        super
      end

      #
      # Feed back info from the scrape
      #
      def after_fetch response, page
        super response, page
        update_spans(response) if (response && response.items)
      end

      # Update intervals to include new response
      def update_spans response
        self.sess_span     << response.span
        self.sess_timespan << response.timespan
      end

      # Return true if the next request would be pointless (true if, perhaps, the
      # response had no items, or the API page limit is reached)
      def is_last? response, page
        sess_span.include?(prev_max) || super(response, page)
      end

      def after_pagination
        self.prev_max      = [prev_max, sess_span.max].compact.max
        self.sess_span     = UnionInterval.new
        self.sess_timespan = UnionInterval.new
        super
      end

      # inject class variables
      def self.included base
        base.class_eval do
          # Span of items gathered in this scrape scrape_job.
          attr_accessor :sess_span, :sess_timespan, :started_at
        end
      end
    end # PaginatedWithLimit

    module PaginatedWithRate
      def before_pagination
        self.sess_items    ||= 0
        super
      end

      #
      # Feed back info from the scrape
      #
      def after_fetch response, page
        super response, page
        update_counts(response) if (response && response.items)
        # p [response.items.map{|item| item['id']}.max, response.items.map{|item| item['id']}.min, prev_max, sess_span, response.parsed_contents.slice('max_id','next_page')]
        # p response.items.map{|item| ("%6.2f" % [Time.now - Time.parse(item['created_at'])])}
      end

      # Count the new items from this response among the session items
      def update_counts response
        self.sess_items += response.num_items
      end
      
      RATE_PARAMETERS = {
        :max_session_timespan  => (60 * 60 * 24 * 5), # 5 days
        :default_scrape_period => (60 * 60 * 2     ), # 2 hours
        :max_resched_delay     => (60 * 60 * 24 * 1), # 1 days
        :min_resched_delay     => (5),                # 5 seconds
        :sess_weight_slowing   => 0.35,  # how fast to converge when rate < average
        :sess_weight_rising    => 1.0,   # how fast to converge when rate > average
      } 
      
      #
      # * session returns one result
      # * session returns no result
      # * session results clustered at center of nominal timespan
      #
      def recalculate_rate!
        # If there's no good session timespan, we can fake one out
        self.sess_timespan.max ||= Time.now.utc
        self.sess_timespan.min ||= self.last_run
        # Whatever its origin, limit the session timespan 
        if sess_timespan.size > RATE_PARAMETERS[:max_session_timespan]
          sess_timespan.min = sess_timespan.max - RATE_PARAMETERS[:max_session_timespan]
        end
        # Find the items rate
        sess_items_rate = sess_items.to_f / sess_timespan.size.to_f
        
        if self.prev_items_rate.blank?
          self.prev_items_rate = target_items_per_job.to_f / RATE_PARAMETERS[:default_scrape_period]
          self.delay           = target_items_per_job / prev_items_rate
        end        
        
        # New items rate is a weighted average of new and old
        #
        # If new rate is faster than the prev_rate, we use a high weight
        # (~1.0). When
        sess_wt         = (sess_items_rate > prev_items_rate) ? RATE_PARAMETERS[:sess_weight_rising] : RATE_PARAMETERS[:sess_weight_slowing]
        new_items_rate  = (prev_items_rate + (sess_items_rate * sess_wt)) / (1.0 + sess_wt)
        new_total_items = prev_items.to_i + sess_items.to_i
        since_start     = (Time.now.utc - self.started_at).to_f
        new_period      = (target_items_per_job / new_items_rate)
        new_delay       = new_period - since_start

        # puts %Q{rates %6.3f %6.3f => %6.3f delay %5.2f %5.2f => %5.2f (%5.2f) want %d sess %d items/%5.1fs -- %10d < %10d -- %s } %
        #   [sess_items_rate, prev_items_rate, new_items_rate,
        #   target_items_per_job / sess_items_rate, self.delay, new_period, new_delay,
        #   target_items_per_job, sess_items, sess_timespan.size.to_f,
        #   sess_span.max, prev_max, 
        #   self.key]
        
        Log.info(
          %Q{resched\tit %4d\t%7.3f\t%7.2f\t%7.2f\t%7.2f\t%7.2f\t%s } %
          [sess_items, sess_timespan.size.to_f, target_items_per_job / sess_items_rate, self.delay, new_period, new_delay, self.key])
        
        self.delay           = new_delay.to_f.clamp(RATE_PARAMETERS[:min_resched_delay], RATE_PARAMETERS[:max_resched_delay])
        self.prev_items_rate = new_items_rate
        self.prev_items      = new_total_items
      end
      
      #
      # Recalculate the item rates
      # using the accumulated response
      #
      def after_pagination
        recalculate_rate!
        self.sess_items    = 0
        super
      end
      
      # inject class variables
      def self.included base
        base.class_eval do
          # Span of items gathered in this scrape scrape_job.
          attr_accessor  :sess_items
          # How many items we hope to pull in for every job
          cattr_accessor :target_items_per_job
        end
      end
    end # PaginatedWithRate
  end
end
