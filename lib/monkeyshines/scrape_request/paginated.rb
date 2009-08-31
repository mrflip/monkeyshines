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
    end # module Paginated

    module Paginating
      #
      # Generates request for each page to be scraped.
      #
      # The includer must define a #request_for_page(job, page) method.
      #
      # * request is generated
      # * ... and yielded to the call block. (which must return the fulfilled
      #   scrape_request response.)
      # * after_fetch method chain invoked
      #
      # Scraping stops when is_last?(response, page) is true
      #
      def each_request job={}, &block
        before_pagination(job)
        (1..hard_request_limit).each do |page|
          request = request_for_page(job, page)
          response = yield request
          after_fetch(job, response, page)
          break if is_last?(job, response, page)
        end
        after_pagination(job)
      end

      # return true if the next request would be pointless (true if, perhaps, the
      # response had no items, or the API page limit is reached)
      def is_last? job, response, page
        ( (page >= response.max_pages) ||
          (response && response.healthy? && (response.num_items < response.max_items)) )
      end

      # Bookkeeping/setup preceding pagination
      def before_pagination job
      end

      # Finalize bookkeeping at conclusion of scrape_job.
      def after_pagination job
      end

      # Feed back info from the fetch
      def after_fetch job, response, page
      end

      # inject class variables
      def self.included base
        base.class_eval do
          # Hard request limit: do not in any case exceed this number of requests
          class_inheritable_accessor :hard_request_limit
        end
      end
    end # module Paginating

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
      def before_pagination job
        self.sess_items    ||= 0
        self.sess_span       = UnionInterval.new
        self.sess_timespan   = UnionInterval.new
        super job
      end

      #
      # Feed back info from the scrape
      #
      def after_fetch job, response, page
        super job, response, page
        return unless response && response.items
        # count_new_items response
        p [response.items.map{|item| item['id']}.max, response.items.map{|item| item['id']}.min, job.prev_max, sess_span, response.parsed_contents.slice('max_id','next_page')]
        update_spans response
      end

      def update_spans response
        # Update intervals
        self.sess_span     << response.span
        self.sess_timespan << response.timespan
      end

      # Return true if the next request would be pointless (true if, perhaps, the
      # response had no items, or the API page limit is reached)
      def is_last? job, response, page
        # Log.debug(['reached prev:', prev_span, sess_span].inspect) if unscraped_span.empty?
        sess_span.include?(job.prev_max) || super(job, response, page)
      end

      def after_pagination job
        # self.prev_items    = prev_items.to_i + sess_items.to_i
        # self.new_items     = sess_items.to_i + new_items.to_i
        job.prev_max       = [job.prev_max, sess_span.max].compact.max
        self.sess_items    = 0
        self.sess_span     = UnionInterval.new
        super
      end

      # inject class variables
      def self.included base
        base.class_eval do
          # Span of items gathered in this scrape scrape_job.
          attr_accessor :sess_items, :sess_span, :sess_timespan
        end
      end
    end

  end
end
