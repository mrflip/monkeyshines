require 'active_support/core_ext/class/inheritable_attributes'
require 'time'
module Monkeyshines
  module Paginated
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

  module PaginatedWithRateAndLimit

    # Set up bookkeeping for pagination tracking
    def before_pagination
      self.sess_items    ||= 0
      self.sess_span       = UnionInterval.new
      self.sess_timespan   = UnionInterval.new
      super
    end

    def after_pagination
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
    def after_fetch response, page
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
  end

end
