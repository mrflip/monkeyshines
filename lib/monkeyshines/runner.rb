require 'trollop'
require 'yaml'
require 'wukong'
require "wukong/extensions/pathname"
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/options'
require 'monkeyshines/scrape_request'

module Monkeyshines
  class Runner
    attr_accessor :options
    attr_accessor :source
    attr_accessor :request_stream
    attr_accessor :fetcher
    attr_accessor :dest
    attr_accessor :periodic_log
    attr_accessor :sleep_time

    DEFAULT_OPTIONS = {
      :source     => { :type => :simple_request_stream, },
      :dest       => { :type => :flat_file_store, :filemode => 'w'},
      :fetcher    => { :type => :http_fetcher,     },
      :log        => { :dest => nil, :iters => 100, :time => 30 },
      :skip       => nil,
      :sleep_time => 0.5
    }

    def initialize *options_hashes
      self.options = Hash.deep_sum(
        Monkeyshines::Runner::DEFAULT_OPTIONS,
        Monkeyshines::CONFIG,
        Monkeyshines::Options.options_from_cmdline,
        *options_hashes
        )
      self.fetcher = Monkeyshines::Fetcher.create(       options[:fetcher])
      self.source  = Monkeyshines::RequestStream.create( options[:source])
      self.dest    = Monkeyshines::Store.create(         options[:dest])
      self.sleep_time = options[:sleep_time]
    end

    def request_from_raw *raw_req_args
      Monkeyshines::ScrapeRequest.new(*raw_req_args)
    end

    def periodic_log
      @periodic_log ||= Monkeyshines::Monitor::PeriodicLogger.new(options[:log])
    end

    def before_scrape
      source.skip!(options[:skip].to_i) if options[:skip]
    end

    def log_line result
      result_log_line = result.blank? ? ['-','-','-'] : [result.response_code, result.url, result.contents.to_s[0..80]]
      [ dest.log_line, result_log_line ].flatten
    end

    def fetch_and_store req
      # some stores (eg.conditional) only call fetcher if url key is missing.
      dest.set(req.url) do
        response = fetcher.get(req)       # do the url fetch
        return unless response.healthy?   # don't store bad fetches
        [response.scraped_at, response]   # timestamp for bookkeeper, result for dest
      end
    end

    #
    # * For each entry in #source,
    # ** create scrape_request(s)
    # ** fetch request (...if appropriate)
    # ** store result (...if fetch was successful)
    # ** do logging
    #
    def run
      Monkeyshines.logger.info "Beginning scrape itself"
      before_scrape()
      source.each do |req|
        next unless req
        result = fetch_and_store(req)
        periodic_log.periodically{ self.log_line(result) }
        sleep sleep_time
      end
      dest.close
      fetcher.close
    end

  end
end
