#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'; $: << File.dirname(__FILE__)
#require 'rubygems'
# require 'wukong'
require 'monkeyshines'
# require 'monkeyshines/utils/uri'
# require 'monkeyshines/utils/filename_pattern'
# require 'monkeyshines/store/conditional_store'
# require 'monkeyshines/fetcher/http_head_fetcher'
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
BASE_URL     = "http://is.gd/"
RADIX        = 62
HANDLE       = BASE_URL.gsub(%r{^http://},'').gsub(/\.com$/,'').gsub(/\W+/,'')
BASE_URL_LEN = BASE_URL.length
MAX_TAIL_LEN = BASE_URL_LEN + 2 + 6
SIX_CHARS    = RADIX**6
File.open("rawd/req/shorturl_requests-20090710-#{HANDLE}.tsv"
  ) do |reqfile|
  reqfile.each do |url|
    #decode
    next unless url.length <= MAX_TAIL_LEN
    tail = url.chomp.strip[BASE_URL_LEN..-1] || ''
    # tail.downcase!
    asnum = ShorturlSequence.decode_str tail, RADIX rescue nil  # tail.to_i(36) rescue -1
    next unless asnum && asnum < SIX_CHARS
    size = (asnum / 1_000_000)
    len  = tail.length
    # track stats
    len_histo << len
    num_histo << size
    ltr_histo << "%s-%s" % [len, tail[0..0]] #  + (len > 1 ? '.'* (len-1) : '')
    puts iter if ((iter += 1) % 1_000_000 == 0)

  end
end
puts "Integer magnitude of decoded (M):"
num_histo.dump
puts "Length of encoded:"
len_histo.dump
puts "First Letter:"
ltr_histo.dump


# puts tail.length # [tail.length, tail, tail[-1].to_i].join("\t")
# puts [asnum, tail, url].inspect
