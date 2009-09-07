module Monkeyshines
  def self.url_encode str
    return '' if str.blank?
    str = str.gsub(/ /, '+')
    Addressable::URI.encode_component(str, Addressable::URI::CharacterClasses::UNRESERVED+'+')
  end

  XML_ENCODED_BADNESS = { "\r" => "&#13;", "\n" => "&#10;", "\t" => "&#9;" }
  #
  # Takes an already-encoded XML string and replaces ONLY the characters in
  # XML_ENCODED_BADNESS (by default, \r newline, \n carriage return and \t tab)
  # with their XML encodings (&#10; and so forth).  Doesn't do any other
  # encoding, and leaves exiting entities alone.
  #
  def self.scrub_xml_encoded_badness str
    str.chomp.gsub(/[\r\n\t]/){|c| BAD_CHARS[c]}
  end
end

module Monkeyshines
  #
  # Base class for Scrape requests
  #
  module ScrapeRequestCore

    autoload :SignedUrl,          'monkeyshines/scrape_request/signed_url'
    autoload :Paginated,          'monkeyshines/scrape_request/paginated'
    autoload :Paginating,         'monkeyshines/scrape_request/paginated'
    autoload :PaginatedWithLimit, 'monkeyshines/scrape_request/paginated'

    def initialize *args
      super *args
      if (moreinfo.is_a?(String)) then self.moreinfo = JSON.load(moreinfo) rescue nil  end
      make_url! if (! url)
    end

    def to_hash *args
      hsh = super *args
      if hsh['moreinfo'].is_a?(Hash)
        hsh['moreinfo'] = moreinfo.to_json
      end
      hsh
    end

    def to_a *args
      to_hash.values_of(*members).to_flat
    end

    #
    def healthy?
      (! url.blank?) && (           # has a URL and either:
        scraped_at.blank?        || # hasn't been scraped,
        (! response_code.blank?) || # or has, with response code
        (! contents.blank?) )       # or has, with response
    end

    # Set URL from other attributes
    def make_url!
      self.url = make_url
    end

    def response= response
      return unless response
      self.contents = Monkeyshines.scrub_xml_encoded_badness(response.body)
    end

    def url_encode str
      Monkeyshines.url_encode str
    end

    def key
      Digest::MD5.hexdigest(self.url)
    end

    def req_generation= val
      (self.moreinfo||={})['req_generation'] = val
    end
    def req_generation
      (self.moreinfo||={})['req_generation']
    end

    # inject methods at class level
    module ClassMethods
      # Builds a URL query string from a hash of key,value pairs
      #
      # parameters are in sort order by encoded string
      #
      # Ex.
      #   make_url_query( :foo => 'bar', :q => 'happy meal', :angle => 90 )
      #   #=> "angle=90&foo=bar&q=happy%20meal"
      #
      def make_url_query hsh
        hsh.map{|attr, val| "#{attr}=#{Monkeyshines.url_encode(val)}" }.sort.join("&")
      end
    end
    def self.included base
      base.class_eval do
        include ClassMethods
      end
    end
  end

  class ScrapeRequest < TypedStruct.new(
      [:identifier,       Integer],
      [:page,             Integer],
      [:moreinfo,         String],
      [:url,              String],
      [:scraped_at,       Bignum],
      [:response_code,    Integer],
      [:response_message, String],
      [:contents,         String]
      )
    include ScrapeRequestCore
  end

  #
  # A SimpleRequest just holds a URL and the fetch result.
  #
  class SimpleRequest < TypedStruct.new(
    [:url,              String],
    [:scraped_at,       Bignum],
    [:response_code,    Integer],
    [:response_message, String],
    [:contents,         String]
    )
    include ScrapeRequestCore
  end

end
