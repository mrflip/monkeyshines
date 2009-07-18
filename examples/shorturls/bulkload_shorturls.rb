#!/usr/bin/env ruby
require 'rubygems'
require 'tokyocabinet' ; require 'tokyotyrant'
require 'memcache'
require 'trollop'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/monitor/periodic_monitor'
require 'shorturl_request'
require 'shorturl_sequence'

#
opts = Trollop::options do
  opt :from_type,    'Class name for scrape store to load from',  :type => String
  opt :from,         'URI for scrape store to load from',  :type => String
  opt :into,         'Filename for flat TSV dump', :type => String
  opt :log,          'File to store log', :type => String
end
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
Trollop::die :from_type unless opts[:from_type]

# Load from store
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from])
Monkeyshines.logger.info "Loaded store with #{src_store.size}"

# Store into flat file
dest_store      = Monkeyshines::ScrapeStore::FlatFileStore.new opts[:into], :filemode => 'w'
# dest_store = Monkeyshines::ScrapeStore::TyrantTdbKeyStore.new

# Log
logger = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 100_000, :time_interval => 60)

# Store into flat dump file
src_store.each do |key, hsh|
  req = ShorturlRequest.from_hash hsh
  dest_store.save req
  logger.periodically{ req.to_flat }
end

# On a DB with 2.5M entries optimized for 39M entries, this loads about 250k/min
#
# You can optimize with something like
#   store.db.optimize(2 * 39_000_000, -1, -1, TokyoCabinet::TDB::TLARGE)
