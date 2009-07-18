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
  # opt :dest_db_port,  "Tokyo tyrant db port",                             :type => String
end

# 'shorturl_scrapes-twitter-20090711.tdb'

# Tokyo cabinet
Trollop::die :src_db, "gives the tokyo cabinet db handle to store into" if opts[:src_db].blank?
src_db = TokyoCabinet::TDB.new
src_db.open(opts[:src_db], TokyoCabinet::TDB::OREADER)

# Tokyo Tyrant: store
stores = { }
{
  'tinyurl.com' => 10001,
  'bit.ly'      => 10002,
  'other'       => 10003
}.each do |handle, port|
  stores[handle] = Monkeyshines::ScrapeStore::ReadThruStore.new("", port)
  Trollop::die :store_db, "isn't a tokyo cabinet DB I could load" unless stores[handle].db
end

# Log every N requests
periodic_log    = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 10000, :time_interval => 30)

src_db.iterinit
loop do
  key = src_db.iternext or break
  periodic_log.periodically{ [key, stores['tinyurl.com'].db.rnum, stores['bit.ly'].db.rnum, stores['other'].db.rnum, src_db.rnum] }
  case
  when (key =~ %r{^http://tinyurl.com/(.*)}) then stores['tinyurl.com'].set($1){  src_db[key] }
  when (key =~ %r{^http://bitly/(.*)      }) then stores['bit.ly' ].set($1){      src_db[key] }
  else                                            stores['other'  ].set(key){     src_db[key] }
  end
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
