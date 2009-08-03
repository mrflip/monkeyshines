require 'trollop'
require 'yaml'
require 'wukong'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/store/conditional_store'
require 'monkeyshines/fetcher/http_head_fetcher'

module Monkeyshines
  class Runner
    attr_accessor :options
    attr_accessor :src_store
    attr_accessor :request_stream
    attr_accessor :fetcher
    attr_accessor :dest_store
    attr_accessor :periodic_log

    DEFAULT_OPTIONS = {
      :src_store    => {
        :type => :flat_file_store,
      },
      :fetcher      => {
        :type => :http_fetcher,
      },
    }

    def create factory, plan
      (plan.is_a? Hash) ? factory.from_hash(plan) : plan
    end

    def initialize opts = {}
      self.options         = DEFAULT_OPTIONS.merge opts
      self.fetcher         = create(Monkeyshines::Fetcher, options[:fetcher])
      self.src_store       = create(Monkeyshines::Store, options[:src_store])
      self.request_stream  = options[:request_stream]
      self.dest_store      = create(Monkeyshines::Store, options[:dest_store])
    end

    def periodic_log
      @periodic_log ||= Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 1, :time_interval => 30)
    end

    def request_stream
      @request_stream ||= TwitterRequestStream.new TwitterUserRequest, src_store
    end

    def before_scrape
      src_store.skip!(options[:skip].to_i) if options[:skip]
    end

    #
    # * For each entry in #src_store,
    # ** create scrape_request(s)
    # ** fetch request (...if appropriate)
    # ** store result (...if fetch was successful)
    # ** do logging
    #
    def run
      Monkeyshines.logger.info "Beginning scrape itself"
      before_scrape()
      request_stream.each do |req|
        # conditional store only calls fetcher if url key is missing.
        result = dest_store.set(req.url) do
          response = fetcher.get(req)                             # do the url fetch
          next unless response.healthy?                           # don't store bad fetches
          [response.scraped_at, response]                         # timestamp into cache, result into flat file
        end
        periodic_log.periodically{ [
            #"%7d"%dest_store.misses, 'misses', dest_store.size,
            req.response_code, result, req.url] }
      end
      dest_store.close
      fetcher.close
    end

  end
end
