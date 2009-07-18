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
#
opts = Trollop::options do
  opt :from,            "Flat file of scrapes",   :type => String
end

#
tdb = TokyoCabinet::TDB.new
tdb.open(opts[:from])
#
rdb = TokyoTyrant::RDBTBL.new
rdb.open('', 1978) or raise("Can't open DB: #{rdb.ecode}: #{rdb.errmsg(rdb.ecode)}")

# Log
logger = Monkeyshines::Monitor::PeriodicLogger.new(
  :iter_interval => 100_000, :time_interval => 15)

tdb.iterinit
loop do
  key = tdb.iternext or break
  hsh = tdb[key]
  req = ShorturlRequest.from_hash hsh ; req.url ||= hsh['short_url']
  rdb[key] = req.to_hash
  puts req.to_flat.join("\t")
  logger.periodically{ [ rdb.rnum, tdb.size ] }
end
