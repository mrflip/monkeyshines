require 'trollop'
require 'yaml'
require 'wukong'
require 'pathname'
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

    def initialize opts = {}
      self.options         = DEFAULT_OPTIONS.merge opts
      self.fetcher         = Monkeyshines::Fetcher.create(       options[:fetcher])
      self.request_stream  = Monkeyshines::RequestStream.create( options[:request_stream])
      self.dest_store      = Monkeyshines::Store.create(         options[:dest_store])
    end

    def periodic_log
      @periodic_log ||= Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 1, :time_interval => 30)
    end

    def before_scrape
      src_store.skip!(options[:skip].to_i) if options[:skip]
    end

    def log_line result
      [ dest_store.log_line,
        result.response_code, result.url, result.contents.to_s[0..80]]
    end

    def fetch_and_store req
      # some stores (eg.conditional) only call fetcher if url key is missing.
      dest_store.set(req.url) do
        response = fetcher.get(req)       # do the url fetch
        return unless response.healthy?     # don't store bad fetches
        [response.scraped_at, response]   # timestamp into cache, result into flat file
      end
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
        result = fetch_and_store(req)
        periodic_log.periodically{ self.log_line(result) }
        sleep 0.5
      end
      dest_store.close
      fetcher.close
    end

  end
end
