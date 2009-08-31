require 'yaml'
require 'monkeyshines/runner_core/options'

module Monkeyshines
  class Runner
    attr_accessor :options
    attr_accessor :fetcher
    attr_accessor :source
    attr_accessor :dest
    attr_accessor :periodic_log
    attr_accessor :sleep_time, :force_fetch

    DEFAULT_OPTIONS = {
      :source      => { :type => :simple_request_stream, },
      :dest        => { :type => :flat_file_store, :filemode => 'w'},
      :fetcher     => { :type => :http_fetcher,     },
      :log         => { :dest => nil, :iters => 100, :time => 30 },
      :skip        => nil,
      :sleep_time  => 0.5,
      :force_fetch => false,
    }

    #
    # Assembles a MonkeyshinesRunner from the given plan.
    #
    # options_hashes is a hash tree of options to build each particular
    # component. The options are deep merged with the class and global defaults.
    #
    # The options for each of :fetcher, :request_stream and :dest are passed to
    # the Fetcher, RequestStream and Store factories respectively
    #
    def initialize *options_hashes
      prepare_options(*options_hashes)
      setup_main_log
      self.source  = create_source
      self.fetcher = create_fetcher
      self.dest    = create_dest
      self.sleep_time  = options[:sleep_time]
      self.force_fetch = options[:force_fetch]
    end

    def create_source
      Monkeyshines::RequestStream.create(options[:source])
    end

    def create_dest
      Monkeyshines::Store.create(options[:dest])
    end

    def create_fetcher
      Monkeyshines::Fetcher.create(options[:fetcher])
    end

    #
    # Deep merges:
    # * the DEFAULT_OPTIONS in runner.rb,
    # * the global Monkeyshines::CONFIG loaded from disk
    # * the options passed in as arguments
    #
    # Options appearing later win out.
    #
    def prepare_options *options_hashes
      self.options = Hash.deep_sum(
        Monkeyshines::Runner::DEFAULT_OPTIONS,
        Monkeyshines::CONFIG,
        *options_hashes
        )
    end


    def self.define_cmdline_options &block
      yield :handle,          "Identifying string for scrape",     :type => String, :required => true
      yield :source_filename, "URI for scrape store to load from", :type => String
      yield :dest_filename,   "Filename for results",              :type => String
      yield :log_dest,        "Log file location",                 :type => String
      # yield :dest_cache_uri,  "URI for cache server",              :type => String
    end


    #
    # * For each entry in #source,
    # ** create scrape_request(s)
    # ** fetch request (...if appropriate)
    # ** store result (...if fetch was successful)
    # ** do logging
    #
    def run
      Log.info "Beginning scrape itself"
      before_scrape()
      each_request do |req|
        next unless req
        before_fetch(req)
        fetch_and_store(req)
        after_fetch(req)
        sleep sleep_time
        req
      end
      after_scrape()
    end

    #
    # before_scrape filter chain.
    #
    def before_scrape
      source.skip!(options[:skip].to_i) if options[:skip]
    end

    #
    # enumerates requests
    #
    def each_request &block
      source.each(&block)
    end

    #
    # before_scrape filter chain.
    #
    def before_fetch req
    end

    #
    # Fetch and store result
    #
    #
    def fetch_and_store req
      # some stores (eg.conditional) only call fetcher if url key is missing.
      dest.set(req.url, force_fetch) do
        response = fetcher.get(req)       # do the url fetch
        return unless response.healthy?   # don't store bad fetches
        [response.scraped_at, response]   # timestamp for bookkeeper, result for dest
      end
    end

    #
    # after_fetch
    #
    def after_fetch req
      periodic_log.periodically{ self.log_line(req) }
    end

    #
    # after_scrape
    #
    def after_scrape
      dest.close
      fetcher.close
    end

    #
    # Logging
    #
    def setup_main_log
      unless options[:log][:dest].blank?
        log_file = "%s/log/%s" % [WORK_DIR, options[:log][:dest]]
        FileUtils.mkdir_p(File.dirname(log_file))
        $stdout = $stderr = File.open( log_file+"-console.log", "a" )
      end
    end

    def periodic_log
      @periodic_log ||= Monkeyshines::Monitor::PeriodicLogger.new(options[:log])
    end

    def log_line result
      result_log_line = result.blank? ? ['-','-','-'] : [result.response_code, result.url, result.contents.to_s[0..80]]
      [ dest.log_line, result_log_line ].flatten
    end


  end
end
