require 'trollop'
require 'yaml'
require 'wukong'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/store/conditional_store'
require 'monkeyshines/fetcher/http_head_fetcher'
module Monkeyshines
  module Runner

    DEFAULT_OPTS = {

      :src_type          => :flat_file_store,
      :src_name          => nil,
      :src_skip          => nil,

      #
      :fetcher           => :http_fetcher,

      #
      :dest_type         => :conditional_store,
      :dest_cache_name   => nil,
      :dest_filename     => nil,
      :dest_pattern      => nil,
      :dest_pattern_root => nil,
      :dest_chunk_time   => nil,
    }

    #
    # A fetcher
    #
    # * loads ScrapeRequests from a request_src
    # *
    #
    class Base
      attr_accessor :opts
      def initialize opts
        self.opts = opts
      end

      #
      #
      #
      def standard_opts
        opts = Trollop::options do
          opt :log,            "Log file name; leave blank to use STDERR",     :type => String
          # input from file
          opt :src_name,       "URI for scrape store to load from",            :type => String
          opt :src_skip,       "Initial lines to skip",                        :type => Integer
          # output storage
          opt :cache_loc,      "URI for cache server",                         :type => String, :default => ':10022'
          opt :chunk_time,     "Frequency to rotate chunk files (in seconds)", :type => Integer, :default => 60*60*4
          opt :dest_dir,       "Filename base to store output. e.g. --dest_dir=/data/ripd", :type => String, :required => true
          opt :dest_pattern,   "Pattern for dump file output",                 :default => ":dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid.tsv"
        end
        opts[:handle] ||= 'com.twitter'
        scrape_config = YAML.load(File.open(ENV['HOME']+'/.monkeyshines'))
        opts.merge! scrape_config

      end

      # ******************** Log ********************
      def log
        Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
        periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 10000, :time_interval => 30)
      end

      # Source for requests
      def src_store
        @src_store = Monkeyshines::Store::FlatFileStore.new_from_command_line(opts, :filemode => 'r')
        @src_store.skip!(opts[:skip].to_i) if opts[:skip]
      end

      #
      # ConditionalStore requests are only made (and thus data is only output)
      # if the url is missing from the requested hash.
      #
      def dest_store
        return @dest_store if @dest_store
        # Track visited URLs with key-value database
        @dest_cache = Monkeyshines::Store::TyrantRdbKeyStore.new(opts[:cache_loc])
        # Store the data into flat files
        @dest_pattern = Monkeyshines::Utils::FilenamePattern.new(opts[:dest_pattern], :handle => opts[:handle], :dest_dir => opts[:dest_dir])
        @dest_files   = Monkeyshines::Store::ChunkedFlatFileStore.new(dest_pattern, opts[:chunk_time].to_i, opts)
        # dest_store combines them
        @dest_store = Monkeyshines::Store::ConditionalStore.new(@dest_cache, @dest_files)
      end

      def engine
        @fetcher ||= Monkeyshines::Fetcher::HttpFetcher.new opts[:twitter_api]
      end

      #
      # ******************** Do this thing ********************
      #
      def run
        Monkeyshines.logger.info "Beginning scrape itself"
        src_store.each do |req|
          # If url key is missing,
          result = dest_store.set(req.url) do
            response = fetcher.get(req)     # do the url fetch
            next unless response.healthy?   # don't store bad fetches
            [response.scraped_at, response] # timestamp into cache, result into flat file
          end
          periodic_log.periodically{ ["%7d"%dest_store.misses, 'misses', dest_store.size, req.response_code, result, req.url] }
        end
        src_store.close
        dest_store.close
        fetcher.close
      end

    end
  end
end
