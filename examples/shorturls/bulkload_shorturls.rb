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
  opt :log,          'File to store log', :type => String
end
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
Trollop::die :from_type unless opts[:from_type]

# Load from flat file
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from], opts.merge(:filemode => 'r'))

# Store into read-thru cach
TYRANT_PORTS = { 'tinyurl' => ":10001", 'bitly' => ":10002", 'other' => ":10003" }
store = Monkeyshines::ScrapeStore::MultiplexShorturlCache.new(TYRANT_PORTS)

# Log
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 10_000, :time_interval => 60) #

# Crossload from src_store into dest_store
misses = 0
src_store.each_as(ShorturlRequest) do |req|
  periodic_log.periodically{ [ "%7d"%misses, 'misses', dests.map{|k,v| v.size }, req.to_flat[1..-1] ] }
  store.set(req.url){ misses+=1 ; req }
end

# On a DB with 2M entries, this loads about 700/s
#
# You can optimize with something like
#   store.db.optimize(2 * 39_000_000, -1, -1, TokyoCabinet::TDB::TLARGE)
