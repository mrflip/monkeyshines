#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/scrape_store/read_thru_store'
require 'monkeyshines/scrape_engine/http_head_scraper'
require 'shorturl_request'
require 'trollop' # gem install trollop

opts = Trollop::options do
  opt :from,      "Flat file of scrapes", :type => String
  opt :store_db,  "Tokyo cabinet db name", :type => String
end

# Request stream
Trollop::die :from, "gives the scrapes to load" if opts[:from].blank?
request_stream = Monkeyshines::FlatFileRequestStream.new(opts[:from], ShorturlRequest)
# Scrape Store
Trollop::die :store_db, "gives the tokyo cabinet db handle to store into" if opts[:store_db].blank?
store = Monkeyshines::ScrapeStore::ReadThruStore.new(opts[:store_db], true) # must exist
Trollop::die :store_db, "isn't a tokyo cabinet DB I could load" unless store.db

# Scraper
scraper = Monkeyshines::ScrapeEngine::HttpHeadScraper.new('bit.ly')


# Bulk load into read-thru cache.
iter  = 0
request_stream.each do |url|
  scrape_request = ShorturlRequest.new url
  # $stderr.puts [Time.now, iter, scrape_request.url].join("\t") if ((iter+=1) % 1 == 0)
  # store.set(scrape_request.url){ scrape_request }
  result = scraper.get scrape_request.url
  p result
  sleep 1
end
store.close
scraper.finish
