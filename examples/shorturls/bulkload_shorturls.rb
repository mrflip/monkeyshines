#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/scrape_store/read_thru_store'
require 'monkeyshines/request_stream'
require 'shorturl_request'
require 'trollop' # gem install trollop

require 'tokyocabinet'

opts = Trollop::options do
  opt :src_db,        "Tokyo cabinet db name",                            :type => String
  opt :dest_db_port,  "Tokyo tyrant db port",                             :type => String
end

# 'shorturl_scrapes-twitter-20090711.tdb'

# Tokyo cabinet
Trollop::die :src_db, "gives the tokyo cabinet db handle to store into" if opts[:src_db].blank?
src_db = TokyoCabinet::TDB.new
src_db.open(opts[:src_db], TokyoCabinet::TDB::OREADER)

# Tokyo Tyrant: store
Trollop::die :dest_db_port, "gives the tokyo cabinet db handle to store into" if opts[:dest_db_port].blank?
store = Monkeyshines::ScrapeStore::ReadThruStore.new("", opts[:dest_db_port])
Trollop::die :store_db, "isn't a tokyo cabinet DB I could load" unless store.db
# Log every N requests
periodic_log    = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 10000, :time_interval => 30)

# [ 'tinyurl.com', 'bitly', 'other' ].each_with_index do




src_db.iterinit
loop do
  key = src_db.iternext or break
  periodic_log.periodically{ [key, store.db.rnum, src_db.rnum] }
  next unless key =~ %r{http://tinyurl.com}
  store.set(key){ src_db[key] }
end

# store.db.iterinit
# loop do
#   key = store.db.iternext or break
#   puts key
# end
# store.close


# On a DB with 2.5M entries optimized for 39M entries, this loads about 250k/min
#
# You can optimize with something like
#   store.db.optimize(2 * 39_000_000, -1, -1, TokyoCabinet::TDB::TLARGE)
