module ShorturlSequence
  # http://refactormycode.com/codes/125-base-62-encoding
  BASE62_CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a
  BASE62_MAP   = Hash.zip(BASE62_CHARS, (0..61).to_a)
  def self.to_s_62 i
    return '0' if i == 0
    s = ''
    while i > 0
      s << BASE62_CHARS[i.modulo(62)]
      i /= 62
    end
    s.reverse
  end


  def self.to_i_62 str
    i_out = 0
    str.reverse.chars.each_with_index do |c, i|
      i_out += BASE62_MAP[c] * (62 ** i)
    end
    i_out
  end

  def self.encode_integer i, radix
    case radix.to_s
    when '36' then i.to_s(36)
    when '62' then to_s_62(i)
    else
      raise "Can't encode into base #{radix}"
    end
  end

  def self.decode_str s, radix
    case radix.to_s
    when '36' then s.to_i(36)
    when '62' then to_i_62(s)
    else
      raise "Can't encode into base #{radix}"
    end
  end
end


class SequentialUrlRequestStream < Monkeyshines::RequestStream::Base
  attr_accessor :base_url, :request_pattern
  def initialize base_url,  request_pattern
    self.base_url        = base_url
    self.request_pattern = request_pattern
  end
  def each *args, &block
    request_pattern.each(*args, &block)
  end
end

class RandomSequentialUrlRequestStream < Monkeyshines::RequestStream::Base
  attr_accessor :base_url, :max_limit, :min_limit, :encoding_radix
  def initialize base_url,  max_limit,  min_limit=0, encoding_radix=36, *args
    super *args
    self.base_url  = base_url
    self.max_limit = max_limit.to_i
    self.min_limit = min_limit.to_i
    self.encoding_radix = encoding_radix
  end

  # An infinite stream of urls in range
  def each *args, &block
    loop do
      yield request_klass.new(url_in_range)
    end
  end

  def url_in_range
    idx = rand(max_limit - min_limit) + min_limit
    base_url + ShorturlSequence.encode_integer(idx, encoding_radix)
  end

  def self.new_from_command_line cmdline_opts, default_opts={}
    options = default_opts.merge(cmdline_opts)
    Trollop::die :base_url  if options[:base_url].blank?
    Trollop::die :max_limit if options[:max_limit].blank?
    request_stream = self.new(options[:base_url], options[:max_limit], options[:min_limit], options[:encoding_radix], options[:request_klass])
    request_stream
  end
end
