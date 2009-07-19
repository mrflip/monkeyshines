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

# require 'ruby-prof'


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
src_store = Monkeyshines::ScrapeStore::TyrantTdbKeyStore.new(src_uri)
Monkeyshines.logger.info "Loaded store with #{src_store.size}"

# ******************** Write into ********************
# dest_store = Monkeyshines::ScrapeStore::FlatFileStore.new(opts[:into], opts.reverse_merge(:filemode => 'w'))
HDB_PORTS = { 'tinyurl' => ":10042", 'bitly' => ":10043", 'other' => ":10044" }
dest_uri = HDB_PORTS[opts[:handle]] or raise "Need a handle (bitly, tinyurl or other). got: #{handle}"
dest_store = Monkeyshines::ScrapeStore::TyrantHdbKeyStore.new(dest_uri)
# src_store_klass = Wukong.class_from_resource('Monkeyshines::ScrapeStore::'+opts[:from_type])
# src_store = src_store_klass.new(opts[:from])
Monkeyshines.logger.info "Loading into store with #{dest_store.size}"

# RubyProf.start

# ******************** Dump ********************
src_store.each do |key, hsh|
  periodic_log.periodically{ [src_store.size, dest_store.size, hsh.values_of('url', 'scraped_at', 'response_code', 'response_message', 'contents')] }
  dest_store.save hsh['url'], hsh['scraped_at']
end

# result = RubyProf.stop
# # Print a flat profile to text
# printer = RubyProf::FlatPrinter.new(result)
# printer.print(STDOUT, 0)
