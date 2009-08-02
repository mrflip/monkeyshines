#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'rubygems'
require 'trollop'
require 'wukong'
require 'monkeyshines'
require 'shorturl_request'
require 'shorturl_sequence'
require 'monkeyshines/utils/uri'
require 'time'

#
# Command line options
#
opts = Trollop::options do
  # opt :from_type,    'Class name for scrape store to load from',  :type => String
  # opt :from,         'URI for scrape store to load from',  :type => String
  opt :handle,       "Handle for scrape", :type => String
  # opt :into,         'Filename for flat TSV dump', :type => String
  opt :log,          'File to store log', :type => String
end

# ******************** Log ********************
Monkeyshines.logger = Logger.new(opts[:log], 'daily') if opts[:log]
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 20_000, :time_interval => 30)

# ******************** Read From ********************
TYRANT_PORTS = { 'tinyurl' => ":10001", 'bitly' => ":10002", 'other' => ":10003" }
src_uri = TYRANT_PORTS[opts[:handle]] or raise "Need a handle (bitly, tinyurl or other). got: #{handle}"
src_store = Monkeyshines::Store::TyrantTdbKeyStore.new(src_uri)
Monkeyshines.logger.info "Loaded store with #{src_store.size}"

# ******************** Write into ********************
# dest_store = Monkeyshines::Store::FlatFileStore.new(opts[:into], opts.reverse_merge(:filemode => 'w'))
RDB_PORTS = { 'tinyurl' => ":10042", 'bitly' => ":10043", 'other' => ":10044" }
dest_uri = RDB_PORTS[opts[:handle]] or raise "Need a handle (bitly, tinyurl or other). got: #{handle}"
dest_store = Monkeyshines::Store::TyrantRdbKeyStore.new(dest_uri)
# src_store_klass = Wukong.class_from_resource('Monkeyshines::Store::'+opts[:from_type])
# src_store = src_store_klass.new(opts[:from])
Monkeyshines.logger.info "Loading into store with #{dest_store.size}"

# ******************** Dump ********************
src_store.each do |key, hsh|
  periodic_log.periodically{ [src_store.size, dest_store.size, hsh.values_of('url', 'scraped_at', 'response_code', 'response_message', 'contents')] }
  dest_store.save hsh['url'], hsh['scraped_at']
end
