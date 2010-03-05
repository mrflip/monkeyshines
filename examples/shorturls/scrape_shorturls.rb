#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__); $: << File.dirname(__FILE__)+'/../../../graphiterb/lib'
require 'rubygems'
require 'wukong'
require 'monkeyshines'
require 'configliere'
#
require 'shorturl_request'
require 'shorturl_sequence'
require 'shorturl_stats'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/store/conditional_store'
require 'monkeyshines/fetcher/http_head_fetcher'
require 'graphiterb' # needs graphiterb - simple ruby interface for graphite
# require 'trollop' # gem install trollop

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

Configliere.use :commandline, :config_file, :define
Settings.read 'shorturls.yaml' #~/.configliere/shorturls.yaml
Settings.define :base_url,     :description => "Host part of URL: eg tinyurl.com", :type => String, :required => true
# Settings.define :log,          :description => "Log file name; leave blank to use STDERR", :type => String
Settings.define :log_time,     :description => "Log time interval, in seconds, for periodic logger and Graphite logger", :type => Integer, :default => 60
Settings.define :log_iters,    :description => "Log iteration interval for periodic logger and Graphite logger", :type => Integer, :default => 10000
# input from file
Settings.define :file_from,    :description => "Location of URLs to scrape", :type => String
Settings.define :file_skip,    :description => "Initial lines to skip", :type => Integer
# OR do a random walk
Settings.define :random,       :description => "Generate and visit random URL suffixes"
Settings.define :random_min,   :description => "Smallest sequential URL to randomly visit",    :type => Integer # default in shorturl_sequence.rb
Settings.define :random_max,   :description => "Largest sequential URL to randomly visit",     :type => Integer # default in shorturl_sequence.rb
Settings.define :random_radix, :description => "36 for most, 62 if URLs are case-sensitive",   :type => Integer, :default => 36
# output storage
Settings.define :cache_loc,      :description => "URI for cache server",                         :type => String
Settings.define :chunk_time,     :description => "Frequency to rotate chunk files (in seconds)", :type => Integer, :default => 60*60*4
Settings.define :rootdir,        :description => "Filename base for output, def /data/ripd",     :type => String,  :default => '/data/ripd/shorturls'
Settings.define :dest_pattern,   :description => "Pattern for dump file output",                 :default => ":rootdir/:date/:handle+:timestamp-:pid.tsv"
Settings.resolve!
Log = Logger.new($stderr) unless defined?(Log)

# Removed trollop optioning, added in configliere instead
# opts = Trollop::options do
#   opt :base_url,       "Host part of URL: eg tinyurl.com",             :type => String, :required => true
#   opt :log,            "Log file name; leave blank to use STDERR",     :type => String
#   # input from file
#   opt :from,           "Location of URLs to scrape",                   :type => String
#   opt :skip,           "Initial lines to skip",                        :type => Integer
#   # OR do a random walk
#   opt :random,         "Generate and visit random URL suffixes"
#   opt :min_limit,      "Smallest sequential URL to randomly visit",    :type => Integer # default in shorturl_sequence.rb
#   opt :max_limit,      "Largest sequential URL to randomly visit",     :type => Integer # default in shorturl_sequence.rb
#   opt :encoding_radix, "36 for most, 62 if URLs are case-sensitive",   :type => Integer, :default => 36
#   # output storage
#   opt :cache_loc,      "URI for cache server",                         :type => String
#   opt :chunk_time,     "Frequency to rotate chunk files (in seconds)", :type => Integer, :default => 60*60*4
#   opt :rootdir,       "Filename base for output, def /data/ripd",     :type => String,  :default => '/data/ripd'
#   opt :dest_pattern,   "Pattern for dump file output",                 :default => ":rootdir/:handle_prefix/:handle/:date/:handle+:timestamp-:pid.tsv"
# end
handle = Settings.base_url.gsub(/\.com$/,'').gsub(/\W+/,'')

#
# ******************** Log ********************
#
# (I don't think the log file name ever gets used)
# Settings.log = (WORK_DIR+"/log/shorturls_#{handle}-#{Time.now.to_flat}.log") if (Settings.log=='')
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iters => Settings.log_iters, :time => Settings.log_time)

#
# ******************** Graphite Sender ***********************
#
graphite_sender = Graphiterb::GraphiteLogger.new(:iters => Settings.log_iters, :time => Settings.log_time)

#
# ******************** Load from store or random walk ********************
#
if Settings.file_from
  # Settings.filename = Settings.file_from
  src_store = Monkeyshines::Store::FlatFileStore.new(:filename => Settings.file_from, :skip => Settings.file_skip.to_i) # + {:filemode => 'r'}
  # src_store.skip!(Settings.file_skip.to_i) if Settings.file_skip
elsif Settings.random
  src_store = Monkeyshines::Store::RandomUrlStream.new_from_command_line(opts)
else
  Settings.die "Need to either say --random or --file_from=filename"
end

#
# ******************** Store output ********************
#
# Track visited URLs with key-value database
#
RDB_PORTS  = { 'tinyurl' => "localhost:10042", 'bitly' => "localhost:10043", 'other' => "localhost:10044" }
cache_loc  = Settings.cache_loc || RDB_PORTS[handle] or raise "Need a handle (bitly, tinyurl or other)."
dest_cache = Monkeyshines::Store::TyrantRdbKeyStore.new(:uri => cache_loc)


# dest_cache = Monkeyshines::Store::MultiplexShorturlCache.new(RDB_PORTS)

#
# Store the data into flat files
#
dest_pattern = Monkeyshines::Utils::FilenamePattern.new(Settings.dest_pattern,
  :handle => 'shorturl-'+handle, :rootdir => Settings.rootdir)
dest_files   = Monkeyshines::Store::ChunkedFlatFileStore.new(:pattern => Settings.dest_pattern,
  :chunk_time => Settings.chunk_time.to_i, :handle => 'shorturl-'+handle, :rootdir => Settings.rootdir)

#
# Conditional store uses the key-value DB to boss around the flat files --
# requests are only made (and thus data is only output) if the url is missing
# from the key-value store.
#
dest_store = Monkeyshines::Store::ConditionalStore.new(:cache => dest_cache, :store => dest_files)

#
# ******************** Fetcher ********************
#
fetcher = Monkeyshines::Fetcher::HttpHeadFetcher.new

#
# ******************** Success/Fail stats ********************
#
stats = ShorturlStats.new(0,0,0,0)

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
    stats.code_sort(response.response_code)                 # count successes (301) and failures (404)
    [response.scraped_at, response]                         # timestamp into cache, result into flat file
  end
  periodic_log.periodically{ ["%7d"%stats.success_tot, 'successes', "%7d"%stats.failure_tot, 'failures', dest_store.size, req.response_code, result, req.url] }
  graphite_sender.periodically do |metrics, iter, since|
    rates = stats.rates_inst
    metrics << ["scraper.shorturl.#{handle}.success_rate", rates[0]]
    metrics << ["scraper.shorturl.#{handle}.failure_rate", rates[1]]
    metrics << ["scraper.shorturl.#{handle}.success_tot_rate", stats.rates_tot[0]]
    metrics << ["scraper.shorturl.#{handle}.failure_tot_rate", stats.rates_tot[1]]
    metrics << ["scraper.shorturl.#{handle}.current_file_size", dest_files.size]
  end
end
dest_store.close
fetcher.close
