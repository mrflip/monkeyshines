#!/usr/bin/env ruby
require 'rubygems'
require 'tokyocabinet' ; require 'tokyotyrant'
require 'trollop'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'shorturl_request'
require 'shorturl_sequence'
require 'multiplex_shorturl_cache'

# Command Line options
opts = Trollop::options do
  opt :from_type,    'Class name for scrape store to load from',  :type => String
  opt :from,         'URI for scrape store to load from',  :type => String
  opt :handle,       "Handle for scrape", :type => String
  opt :log,          'File to store log', :type => String
end
Trollop::die :from_type unless opts[:from_type]

# ******************** Log ********************
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 20_000, :time_interval => 30)

# ******************** Load from flat file ********************
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from], opts.merge(:filemode => 'r'))

# ******************** Store into read-thru cache ********************
HDB_PORTS = { 'tinyurl' => "localhost:10042", 'bitly' => "localhost:10043", 'other' => "localhost:10044" }
dest_uri = HDB_PORTS[opts[:handle]] or raise "Need a handle (bitly, tinyurl or other). got: #{handle}"
dest_store = Monkeyshines::ScrapeStore::TyrantHdbKeyStore.new(dest_uri)
# dest_store = Monkeyshines::ScrapeStore::MultiplexShorturlCache.new(HDB_PORTS)

# ******************** Dump ********************
src_store.each do |_, url, scat, *args|
  periodic_log.periodically{ [dest_store.size, url, scat, args] }
  dest_store.set_nr url, scat
end

#
# On a DB with 2M entries, this loads about 700/s
# You can optimize with something like
#   EXPECTED_MAX_KEYS = 20_000_000
#   store.db.optimize("bnum=#{2*EXPECTED_MAX_KEYS}#opts=l") # large (64-bit), 40M buckets
#
