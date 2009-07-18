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

# ******************** Read From ********************
src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from])
Monkeyshines.logger.info "Loaded store with #{src_store.size}"

# ******************** Write into ********************
# TYRANT_PORTS = { 'tinyurl.com' => 10001, 'bit.ly' => 10002, 'other' => 10003 }
DUMPFILE_BASE = opts[:into]
def make_store uri
  # Monkeyshines::ScrapeStore::TyrantTdbKeyStore.new uri
  Monkeyshines::ScrapeStore::FlatFileStore.new "#{DUMPFILE_BASE+"-"+uri}.tsv", :filemode => 'w'
end
dests = { }
[ 'bitly' # , 'tinyurl', 'other'
].each do |handle|
  dests[handle] = make_store handle
end

# ******************** Log ********************
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 100_000, :time_interval => 15)

# ******************** Cross Load ********************
# Read , process, dump
src_store.each do |key, hsh|
  hsh['contents']             ||= hsh.delete 'expanded_url'
  hsh['response_code']          = nil if hsh['response_code']    == 'nil'
  hsh['contents']               = nil if hsh['contents']         == 'nil'
  unless hsh['contents'] || hsh['response_code']
    # Monkeyshines.logger.info "removing #{hsh.inspect}"
    src_store.db.out(key)
    next
  end
  hsh['response_message']       = nil if hsh['response_message'] == 'nil'
  hsh['url']                  ||= hsh.delete 'short_url'
  req = ShorturlRequest.from_hash hsh
  periodic_log.periodically{ [src_store.size, req.to_flat] }
  # periodic_log.periodically{ [key, dests['tinyurl.com'].db.rnum, dests['bit.ly'].db.rnum, dests['other'].db.rnum, src_db.rnum] }

  case
  when (key =~ %r{^http://tinyurl.com/(.*)}) then dests['tinyurl'].save req # .set($1 ){ req }
  when (key =~ %r{^http://bit.ly/(.*)})      then dests['bitly'  ].save req # .set($1 ){ req }
  else                                            dests['other'  ].save req # .set(key){ req }
  end
  # src_store.save(key, req.to_hash.compact)
end
