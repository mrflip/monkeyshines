#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/lib'
require 'wukong'
require 'monkeyshines'
require 'monkeyshines/http_scraper'

request_filename = ARGV[0]
if ! request_filename
  warn "Please give the name of a file holding URLs to scrape"; exit
end
dump_filename = "/tmp/req_dump.tsv"

class SimpleScrapeRequest < Struct.new(
    :url,
    :scraped_at, :response_code, :response_message,
    :contents )
end

class String
  def to_flat
    self
  end
end

class Monkeyshines::FlatFileScrapeStore
  attr_accessor :file, :filename
  def initialize filename
    self.filename = filename
    self.file     = File.open(filename, "w")
  end
  def << contents
    p contents.to_flat
    self.file << contents.to_flat.join("\t") + "\n"
  end
end

scraper = Monkeyshines::HttpScraper.new('twitter.com')
reqs    = Monkeyshines::FlatFileRequestStream.new(request_filename, SimpleScrapeRequest)
store   = Monkeyshines::FlatFileScrapeStore.new(dump_filename)
reqs.each do |scrape_request|
  p scrape_request
  store << scraper.get(scrape_request)
end
