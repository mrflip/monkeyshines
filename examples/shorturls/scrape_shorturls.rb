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
  opt :from,      "Flat file of scrapes",           :type => String
  opt :store_db,  "Tokyo cabinet db name",          :type => String
  opt :skip,      "Initial requests to skip ahead", :type => Integer
end

# Request stream
#request_stream = Monkeyshines::FlatFileRequestStream.new_from_command_line(opts, :request_klass => ShorturlRequest)

class SequentialUrlRequestStream < Monkeyshines::RequestStream
  attr_accessor :base_url, request_pattern
  def initialize base_url, request_pattern
    self.base_url        = base_url
    self.request_pattern = request_pattern
  end
  def each *args, &block
    request_pattern.each(*args, &block)
  end
end
request_stream = SequentialUrlRequestStream.new('http://tinyurl.com/', ('aaaaaa'..'lszzzz'))

# Scrape Store
store = Monkeyshines::ScrapeStore::ReadThruStore.new_from_command_line opts

# Scraper
scraper = Monkeyshines::ScrapeEngine::HttpHeadScraper.new

# Bulk load into read-thru cache.
Monkeyshines.logger.info "Beginning scrape itself"
Monkeyshines.log_every 100, :scrape_request, :starting_at => opts[:skip]
request_stream.each do |scrape_request|
  next if scrape_request.url =~ %r{\Ahttp://(poprl.com|short.to|timesurl.at)}
  result = store.set( scrape_request.url ){ scraper.get(scrape_request) }
  Monkeyshines.log_occasional(:scrape_request){|iter| [iter, scrape_request.response_code, result, scrape_request.url].join("\t") }
  sleep 0.2
end
store.close
scraper.finish
