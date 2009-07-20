#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
#require 'rubygems'
# require 'wukong'
# require 'monkeyshines'
# require 'monkeyshines/utils/uri'
# require 'monkeyshines/utils/filename_pattern'
# require 'monkeyshines/scrape_store/conditional_store'
# require 'monkeyshines/scrape_engine/http_head_scraper'
# require 'trollop' # gem install trollop
# require 'shorturl_request'
require 'shorturl_sequence'

digits = { } ; (('0'..'9').to_a+('a'..'z').to_a).each do |ch| digits[ch] = 0 end

# (1..10000).each do |idx|
#   s = ShorturlSequence.encode_integer idx, 36
#   digits[s[0..0]] += 1
# end
# p digits
# puts digits.sort.map{|ch,ct| "%-7s\t%10d"%[ch,ct]}

class Histo
  attr_accessor :buckets
  def initialize
    self.buckets = { }
  end
  def << val
    buckets[val] ||= 0
    buckets[val]  += 1
  end
  def dump
    buckets.sort.each do |val, count|
      puts "%10d\t%s"%[count,val]
    end
  end
end

len_histo = Histo.new
num_histo = Histo.new
ltr_histo = Histo.new
iter = 0

# 123456789-123456789-
# http://bit.ly/
# http://tinyurl.com/
BASE_URL_LEN = 'http://tinyurl.com/'.length
MAX_TAIL_LEN = BASE_URL_LEN + 2 + 6
SIX_CHARS    = 36**6
File.open('rawd/req/shorturl_requests-20090710-tinyurl.tsv') do |reqfile|
  reqfile.each do |url|
    #decode
    next unless url.length == MAX_TAIL_LEN
    tail = url.chomp.strip[BASE_URL_LEN..-1] || ''
    tail.downcase!
    asnum = tail.to_i(36) rescue -1
    next if asnum > SIX_CHARS
    size = (asnum / 1_000_000)
    len  = tail.length
    # track stats
    len_histo << len
    num_histo << size
    ltr_histo << len.to_s+tail[0..0]
    puts iter if ((iter += 1) % 1_000_000 == 0)

  end
end
puts "Size of decoded:"
num_histo.dump
puts "Length of encoded:"
len_histo.dump
puts "First Letter:"
ltr_histo.dump


# puts tail.length # [tail.length, tail, tail[-1].to_i].join("\t")
# puts [asnum, tail, url].inspect
