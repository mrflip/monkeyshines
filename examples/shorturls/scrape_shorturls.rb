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
require 'monkeyshines/store/conditional_store'
require 'monkeyshines/fetcher/http_head_fetcher'
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
  opt :base_url,       "Host part of URL: eg tinyurl.com",             :type => String, :required => true
  opt :log,            "Log file name; leave blank to use STDERR",     :type => String
  # input from file
  opt :from,           "Location of URLs to scrape",                   :type => String
  opt :skip,           "Initial lines to skip",                        :type => Integer
  # OR do a random walk
  opt :random,         "Generate and visit random URL suffixes"
  opt :min_limit,      "Smallest sequential URL to randomly visit",    :type => Integer # default in shorturl_sequence.rb
  opt :max_limit,      "Largest sequential URL to randomly visit",     :type => Integer # default in shorturl_sequence.rb
  opt :encoding_radix, "36 for most, 62 if URLs are case-sensitive",   :type => Integer, :default => 36
  # output storage
  opt :cache_loc,      "URI for cache server",                         :type => String
  opt :chunk_time,     "Frequency to rotate chunk files (in seconds)", :type => Integer, :default => 60*60*4
  opt :dest_dir,       "Filename base for output, def /data/ripd",     :type => String,  :default => '/data/ripd'
  opt :dest_pattern,   "Pattern for dump file output",                 :default => ":dest_dir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid.tsv"
end
handle = opts[:base_url].gsub(/\.com$/,'').gsub(/\W+/,'')

# ******************** Log ********************
opts[:log] = (WORK_DIR+"/log/shorturls_#{handle}-#{Time.now.to_flat}.log") if (opts[:log]=='')
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iters => 10000, :time => 30)

#
# ******************** Load from store or random walk ********************
#
if opts[:from]
  src_store = Monkeyshines::Store::FlatFileStore.new_from_command_line(opts, :filemode => 'r')
  src_store.skip!(opts[:skip].to_i) if opts[:skip]
elsif opts[:random]
  src_store = Monkeyshines::Store::RandomUrlStream.new_from_command_line(opts)
else
  Trollop::die "Need to either say --random or --from=filename"
end

#
# ******************** Store output ********************
#
# Track visited URLs with key-value database
#
RDB_PORTS  = { 'tinyurl' => "localhost:10042", 'bitly' => "localhost:10043", 'other' => "localhost:10044" }
cache_loc  = opts[:cache_loc] || RDB_PORTS[handle] or raise "Need a handle (bitly, tinyurl or other)."
dest_cache = Monkeyshines::Store::TyrantRdbKeyStore.new(cache_loc)
# dest_cache = Monkeyshines::Store::MultiplexShorturlCache.new(RDB_PORTS)

#
# Store the data into flat files
#
dest_pattern = Monkeyshines::Utils::FilenamePattern.new(opts[:dest_pattern],
  :handle => 'shorturl-'+handle, :dest_dir => opts[:dest_dir])
dest_files   = Monkeyshines::Store::ChunkedFlatFileStore.new(dest_pattern,
  opts[:chunk_time].to_i, opts)

#
# Conditional store uses the key-value DB to boss around the flat files --
# requests are only made (and thus data is only output) if the url is missing
# from the key-value store.
#
dest_store = Monkeyshines::Store::ConditionalStore.new(dest_cache, dest_files)

#
# ******************** Fetcher ********************
#
fetcher = Monkeyshines::Fetcher::HttpHeadFetcher.new

#
# ******************** Do this thing ********************
#
Log.info "Beginning scrape itself"
src_store.each do |bareurl, *args|
  # prepare the request
  next if bareurl =~ %r{\Ahttp://(poprl.com|short.to|timesurl.at|bkite.com)}
  req = ShorturlRequest.new(bareurl, *args)

  # conditional store only calls fetcher if url key is missing.
  result = dest_store.set( req.url ) do
    response = fetcher.get(req)                             # do the url fetch
    next unless response.response_code || response.contents # don't store bad fetches
    [response.scraped_at, response]                         # timestamp into cache, result into flat file
  end
  periodic_log.periodically{ ["%7d"%dest_store.misses, 'misses', dest_store.size, req.response_code, result, req.url] }
end
dest_store.close
fetcher.close
