require 'yaml'

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

    def initialize *options_hashes
      self.options = Hash.deep_sum(
        Monkeyshines::Runner::DEFAULT_OPTIONS,
        Monkeyshines::CONFIG,
        *options_hashes
        )
      setup_main_log
      self.fetcher = Monkeyshines::Fetcher.create(       options[:fetcher])
      self.source  = Monkeyshines::RequestStream.create( options[:source])
      self.dest    = Monkeyshines::Store.create(         options[:dest])
      self.sleep_time  = options[:sleep_time]
      self.force_fetch = options[:force_fetch]
    end

    def request_from_raw *raw_req_args
      Monkeyshines::ScrapeRequest.new(*raw_req_args)
    end

    def setup_main_log
      if (options[:log][:dest])
        log_file = "%s/log/%s" % [WORK_DIR.expand_path, options[:log][:dest]]
        p [log_file, options[:log][:dest].to_s]
        Monkeyshines.logger = Logger.new(log_file+'.log', 'daily')
        $stdout = $stderr   = File.open( log_file+"-console.log", "a")
      end
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
      dest.set(req.url, force_fetch) do
        response = fetcher.get(req)       # do the url fetch
        return unless response.healthy?   # don't store bad fetches
        [response.scraped_at, response]   # timestamp for bookkeeper, result for dest
      end
    end

    def bookkeep result
      periodic_log.periodically{ self.log_line(result) }
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
        fetch_and_store(req)
        bookkeep req
        sleep sleep_time
      end
      dest.close
      fetcher.close
    end

  end
end
