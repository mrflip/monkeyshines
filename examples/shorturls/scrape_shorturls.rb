#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/scrape_store/read_thru_store'
require 'monkeyshines/scrape_engine/http_head_scraper'
require 'shorturl_request'
require 'shorturl_sequence'
require 'trollop' # gem install trollop

#
# Example usage:
#
#    nohup ./scrape_shorturls.rb --base-url='http://tinyurl.com/' --encoding_radix=36 \
#      --create-db=true --store-db rawd/shorturl_scrapes-sequential-`datename`.tdb
#      --max-limit=1200000000 --min-limit=200000000  >> log/shorturl_scrapes-sequential-`datename`.log &
#
#
opts = Trollop::options do
  opt :from,            "Flat file of scrapes",                                                      :type => String
  opt :store_db,        "Tokyo cabinet db name",                                                     :type => String
  opt :create_db,       "Create Tokyo cabinet if --store-db doesn\'t exist?",                        :type => String, :default => false
  opt :skip,            "Initial requests to skip ahead",                                            :type => Integer
  opt :base_url,        "First part of URL incl. scheme and trailing slash, eg http://tinyurl.com/", :type => String
  opt :min_limit,       "Smallest sequential URL to randomly visit",                                 :type => Integer
  opt :max_limit,       "Largest sequential URL to randomly visit",                                  :type => Integer
  opt :encoding_radix,  "Modulo for turning int index into tinyurl string",                          :type => Integer
end

# Request stream
if opts[:from]
  request_stream = Monkeyshines::FlatFileRequestStream.new_from_command_line(opts, :request_klass => ShorturlRequest)
elsif opts[:base_url]
  request_stream =    RandomSequentialUrlRequestStream.new_from_command_line(opts, :request_klass => ShorturlRequest)
else raise "Need either a --from flat file to read or a --base_url to draw requests from" end

# Scrape Store
store   = Monkeyshines::ScrapeStore::ReadThruStore.new_from_command_line opts

# Scraper
scraper = Monkeyshines::ScrapeEngine::HttpHeadScraper.new

# Log
periodic_log = Monkeyshines::Monitor::PeriodicLogger.new(:iter_interval => 10, :starting_at => opts[:skip], :time_interval => 60)

# Bulk load into read-thru cache.
Monkeyshines.logger.info "Beginning scrape itself"
request_stream.each do |scrape_request|
  # next if scrape_request.url =~ %r{\Ahttp://(poprl.com|short.to|timesurl.at)}
  result = store.set( scrape_request.url ){ scraper.get(scrape_request) }
  periodic_log.periodically{ [store.size, scrape_request.response_code, result, scrape_request.url] }
  sleep 0.1
end
store.close
scraper.finish
