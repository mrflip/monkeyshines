#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'shorturl_request'
require 'shorturl_sequence'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/scrape_store/conditional_store'
require 'monkeyshines/scrape_engine/http_head_scraper'
require 'trollop' # gem install trollop

#
# Example usage:
#
#    nohup ./scrape_shorturls.rb --base-url='http://tinyurl.com/' --encoding_radix=36 \
#      --create-db=true --store-db rawd/shorturl_scrapes-sequential-`datename`.tdb
#      --max-limit=1200000000 --min-limit=200000000  >> log/shorturl_scrapes-sequential-`datename`.log &
#
#
opts = Trollop::options do
  opt :dumpfile_dir,        "Filename base to store output. e.g. --dump_basename=/data/ripd",        :type => String
  opt :dumpfile_pattern,    "Pattern for dump file output",                     :default => ":dumpfile_dir/:handle_prefix/:handle/:date/:handle+:datetime-:pid.tsv"
  opt :dumpfile_chunk_time, "Frequency to rotate chunk files (in seconds)",     :default => 60*60*4, :type => Integer
  opt :from_type,    'Class name for scrape store to load from',  :type => String
  opt :from,         'URI for scrape store to load from',  :type => String
  opt :skip,            "Initial requests to skip ahead",                                            :type => Integer
  opt :handle,       "Handle for scrape", :type => String
  #
  # opt :base_url,        "First part of URL incl. scheme and trailing slash, eg http://tinyurl.com/", :type => String
  # opt :min_limit,       "Smallest sequential URL to randomly visit",                                 :type => Integer
  # opt :max_limit,       "Largest sequential URL to randomly visit",                                  :type => Integer
  # opt :encoding_radix,  "Modulo for turning int index into tinyurl string",                          :type => Integer
  #
  opt :log,          'File to store log', :type => String
end

# ******************** Log ********************
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 1000, :time_interval => 30)

# ******************** Load from store ********************
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from], opts.merge(:filemode => 'r'))

# ******************** Track visited URLs with hash
HDB_PORTS = { 'tinyurl' => "localhost:10042", 'bitly' => "localhost:10043", 'other' => "localhost:10044" }
dest_uri = HDB_PORTS[opts[:handle]] or raise "Need a handle (bitly, tinyurl or other). got: #{handle}"
dest_cache = Monkeyshines::ScrapeStore::TyrantHdbKeyStore.new(dest_uri)
# dest_cache = Monkeyshines::ScrapeStore::MultiplexShorturlCache.new(HDB_PORTS)

# ******************** Write into ********************
# Scrape Store for completed requests
dumpfile_pattern  = Monkeyshines::Utils::FilenamePattern.new(opts[:dumpfile_pattern],
  :handle => 'shorturl-'+opts[:handle], :dumpfile_dir => opts[:dumpfile_dir])
dumpfile          = Monkeyshines::ScrapeStore::ChunkedFlatFileStore.new(dumpfile_pattern,
  opts[:dumpfile_chunk_time].to_i, opts.merge(:filemode => 'w'))

# ******************** Conditional Store ********************
dest_store = Monkeyshines::ScrapeStore::ConditionalStore.new(dest_cache, dumpfile)

# ******************** Scraper ********************
scraper = Monkeyshines::ScrapeEngine::HttpHeadScraper.new

# Bulk load into read-thru cache.
Monkeyshines.logger.info "Beginning scrape itself"
src_store.each do |bareurl, *args|
  next if bareurl =~ %r{\Ahttp://(poprl.com|short.to|timesurl.at)}
  #
  req    = ShorturlRequest.new(bareurl, *args)
  result = dest_store.set( req.url ) do
    response = scraper.get(req)      # do the url fetc
    [response.scraped_at, response]  # timestamp into cache, result into flat file
  end
  periodic_log.periodically{ ["%7d"%dest_store.misses, 'misses', dest_store.size, req.response_code, result, req.url] }
end
dest_store.close
scraper.finish
