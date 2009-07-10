#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/lib'
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/scrape_store/read_thru_cache'

request_filename = ARGV[0]
if ! request_filename
  warn "Please give the name of a file holding URLs to scrape"; exit
end
dump_filename = "/tmp/req_dump.tsv"

class ShorturlRequest < Struct.new(
    :short_url,
    :scraped_at, :response_code, :response_message,
    :contents )
end

class String
  def to_flat
    self
  end
end

class Monkeyshines::FlatFileRequestStream
  attr_accessor :request_file
  def initialize filename
    self.request_file = File.open(filename)
  end
  def each &block
    self.request_file.each do |line|

    end
  end
end

scraper = Monkeyshines::HttpScraper.new('twitter.com')
reqs    = Monkeyshines::FlatFileRequestStream.new(request_filename, SimpleScrapeRequest)
store   = Monkeyshines::FlatFileScrapeStore.new(dump_filename)
reqs.each do |scrape_request|
  p scrape_request
  store << scraper.get(scrape_request)
end
