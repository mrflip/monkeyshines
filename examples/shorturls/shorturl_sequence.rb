module Base62
  # http://refactormycode.com/codes/125-base-62-encoding
  BASE62_CHARS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a
  BASE62_MAP   = {}
  BASE62_CHARS.zip((0..61).to_a){|ch,num| BASE62_MAP[ch]=num }
  def self.i_to_s i
    return '0' if i == 0
    s = ''
    while i > 0
      s << BASE62_CHARS[i.modulo(62)]
      i /= 62
    end
    s.reverse
  end

  def self.s_to_i str
    i_out = 0
    str.reverse.chars.each_with_index do |c, i|
      i_out += BASE62_MAP[c] * (62 ** i)
    end
    i_out
  end
end

module ShorturlSequence
  def self.encode_integer i, radix
    case radix.to_s
    when '36' then i.to_s(36)
    when '62' then Base62.i_to_s(i)
    else
      raise "Can't encode into base #{radix}"
    end
  end

  def self.decode_str s, radix
    s = s.gsub(%r{\W+$},'')
    case radix.to_s
    when '36' then s.to_i(36)
    when '62' then Base62.s_to_i(i)
    else
      raise "Can't encode into base #{radix}"
    end
  end
end

class Shorturl
  attr_accessor :base_url
  attr_accessor :token
  def initialize token
    self.token    = token
  end
end

class Shorturl62
  def to_i
    Base62.s_to_i token
  end

  def to_s
    url
  end

  def url
    "#{base_url}/#{token}"
  end
end

class IsgdShorturl < Shorturl62
  def base_url
    'http://is.gd'
  end
end

class Monkeyshines::ScrapeStore::SequentialUrlStream
  DEFAULT_MAX_URLSTR = '1zzzzz'.to_i(36)
  DEFAULT_RADIX = {
    'http://tinyurl.com/' => 36,
    'http://bit.ly/'      => 62,
    'http://is.gd/'       => 62,
  }
  attr_accessor :base_url, :min_limit,   :span,                        :encoding_radix
  def initialize base_url,  min_limit=0,  max_limit=nil, encoding_radix=nil
    self.base_url  = self.class.fix_url(base_url)
    self.min_limit = min_limit.to_i
    max_limit    ||= DEFAULT_MAX_URLSTR
    self.span      = max_limit.to_i - self.min_limit
    self.encoding_radix = (encoding_radix || DEFAULT_RADIX[self.base_url]).to_i
    raise "Please specify either encoding_radix of 36 or 62" unless [36, 62].include?(self.encoding_radix)
  end

  def self.fix_url url
    url = 'http://' + url unless (url[0..6]=='http://')
    url = url + '/'       unless (url[-1..-1]=='/')
    url
  end

  # An infinite stream of urls in range
  def each *args, &block
    (min_limit..max_limit).each(&block)
  end

  def self.new_from_command_line cmdline_opts, default_opts={}
    options = default_opts.merge(cmdline_opts)
    Trollop::die :base_url  if options[:base_url].blank?
    self.new *options.values_of(:base_url, :min_limit, :max_limit, :encoding_radix)
  end
end

class Monkeyshines::ScrapeStore::RandomUrlStream < Monkeyshines::ScrapeStore::SequentialUrlStream
  # An infinite stream of urls in range
  def each *args, &block
    loop do
      yield url_in_range
    end
  end

  def url_in_range
    idx = rand(span) + min_limit
    base_url + ShorturlSequence.encode_integer(idx, encoding_radix)
  end
end
