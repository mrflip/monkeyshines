#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'rubygems'
require 'wukong'
require 'monkeyshines'
#
require 'shorturl_request'
require 'shorturl_sequence'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/scrape_store/conditional_store'
require 'monkeyshines/scrape_engine/http_head_scraper'
require 'trollop' # gem install trollop

# ===========================================================================
#
# scrape_shorturls.rb --
#
# To scrape from a list of shortened urls:
#
#    ./shorturl_random_scrape.rb --from-type=FlatFileStore --from=request_urls.tsv
#
# To do a random scrape:
#
#    ./shorturl_random_scrape.rb --from-type=RandomUrlStream --base-url=tinyurl.com
#       --base-url="http://tinyurl.com" --min-limit= --max-limit= --encoding_radix=
#
#
opts = Trollop::options do
  opt :base_url,       "Host part of URL: eg tinyurl.com",             :type => String
  opt :log,            "Log file name; leave blank to use STDERR",     :type => String
  # input from file
  opt :from_type,      "Class name for scrape store to load from",     :type => String
  opt :from,           "URI for scrape store to load from",            :type => String
  opt :skip,           "Initial lines to skip",                        :type => Integer
  # OR do a random walk
  opt :min_limit,      "Smallest sequential URL to randomly visit",    :type => Integer
  opt :max_limit,      "Largest sequential URL to randomly visit",     :type => Integer
  opt :encoding_radix, "36 for most, 62 if URLs are case-sensitive",   :type => Integer
  # output storage
  opt :cache_loc,      "URI for cache server",                         :type => String
  opt :chunk_time,     "Frequency to rotate chunk files (in seconds)", :type => Integer, :default => 60*60*4
  opt :dest_dir,       "Filename base to store output. e.g. --dump_basename=/data/ripd", :type => String
  opt :dest_pattern,   "Pattern for dump file output",                 :default => ":dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid.tsv"
end
# ******************** Log ********************
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 1000, :time_interval => 30)

#
# ******************** Load from store or random walk ********************
#
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type]) or raise "Can't load #{opts[:from_type]}. Try --from-type=RandomUrlStream or --from-type=FlatFileStore"
src_store = src_store_klass.new_from_command_line(opts, :filemode => 'r')
src_store.skip!(opts[:skip].to_i) if opts[:skip]

#
# ******************** Store output ********************
#
# Track visited URLs with key-value database
#
handle = opts[:base_url].gsub(/\.com$/,'').gsub(/\W+/,'')
HDB_PORTS  = { 'tinyurl' => "localhost:10042", 'bitly' => "localhost:10043", 'other' => "localhost:10044" }
cache_loc  = opts[:cache_loc] || HDB_PORTS[handle] or raise "Need a handle (bitly, tinyurl or other)."
dest_cache = Monkeyshines::ScrapeStore::TyrantHdbKeyStore.new(cache_loc)
# dest_cache = Monkeyshines::ScrapeStore::MultiplexShorturlCache.new(HDB_PORTS)

#
# Store the data into flat files
#
dest_pattern = Monkeyshines::Utils::FilenamePattern.new(opts[:dest_pattern],
  :handle => 'shorturl-'+handle, :dest_dir => opts[:dest_dir])
dest_files   = Monkeyshines::ScrapeStore::ChunkedFlatFileStore.new(dest_pattern,
  opts[:chunk_time].to_i, opts)

#
# Conditional store uses the key-value DB to boss around the flat files --
# requests are only made (and thus data is only output) if the url is missing
# from the key-value store.
#
dest_store = Monkeyshines::ScrapeStore::ConditionalStore.new(dest_cache, dest_files)

#
# ******************** Scraper ********************
#
scraper = Monkeyshines::ScrapeEngine::HttpHeadScraper.new

#
# ******************** Do this thing ********************
#
Monkeyshines.logger.info "Beginning scrape itself"
src_store.each do |bareurl, *args|
  # prepare the request
  next if bareurl =~ %r{\Ahttp://(poprl.com|short.to|timesurl.at|bkite.com)}
  req = ShorturlRequest.new(bareurl, *args)

  # conditional store only calls scraper if url key is missing.
  result = dest_store.set( req.url ) do
    response = scraper.get(req)                             # do the url fetch
    next unless response.response_code || response.contents # don't store bad fetches
    [response.scraped_at, response]                         # timestamp into cache, result into flat file
  end

  periodic_log.periodically{ ["%7d"%dest_store.misses, 'misses', dest_store.size, req.response_code, result, req.url] }
end
dest_store.close
scraper.close
