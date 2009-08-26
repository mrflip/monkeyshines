#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'rubygems'
require 'trollop'
require 'wukong'
require 'monkeyshines'
require 'shorturl_request'
require 'shorturl_sequence'
require 'monkeyshines/utils/uri'

#
# Command line options
#
opts = Trollop::options do
  opt :from_type,    'Class name for scrape store to load from',  :type => String
  opt :from,         'URI for scrape store to load from',  :type => String
  opt :into,         'Filename for flat TSV dump', :type => String
  opt :log,          'File to store log', :type => String
end
Trollop::die :from_type unless opts[:from_type]

# ******************** Read From ********************
src_store_klass = Wukong.class_from_resource('Monkeyshines::Store::'+opts[:from_type])
src_store = src_store_klass.new(opts[:from])
Log.info "Loaded store with #{src_store.size}"

# ******************** Write into ********************
DUMPFILE_BASE = opts[:into]
def make_store uri
  Monkeyshines::Store::FlatFileStore.new "#{DUMPFILE_BASE+"-"+uri}.tsv", :filemode => 'w'
end
dests = { }
[ 'tinyurl', 'bitly', 'other'
].each do |handle|
  dests[handle] = make_store handle
end

# ******************** Log ********************
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iters => 20_000, :time => 30)

# ******************** Cross Load ********************
# Read , process, dump
iter = 0
src_store.each do |key, hsh|
  hsh['contents']             ||= hsh.delete 'expanded_url'
  hsh['response_code']          = nil if hsh['response_code']    == 'nil'
  hsh['contents']               = nil if hsh['contents']         == 'nil'
  unless hsh['contents'] || hsh['response_code']
    # Log.info "removing #{hsh.inspect}"
    src_store.db.out(key)
    next
  end
  hsh['response_message']       = nil if hsh['response_message'] == 'nil'
  hsh['url']                  ||= hsh.delete 'short_url'
  req = ShorturlRequest.from_hash hsh
  periodic_log.periodically{ [src_store.size, req.to_flat] }

  req.contents = Addressable::URI.scrub_url req.contents if req.contents

  case
  when (key =~ %r{^http://tinyurl.com/(.*)}) then dests['tinyurl'].save req
  when (key =~ %r{^http://bit.ly/(.*)})      then dests['bitly'  ].save req
  else                                            dests['other'  ].save req
  end
  # src_store.save(key, req.to_hash.compact)
end
