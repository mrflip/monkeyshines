module Monkeyshines

  #
  # Base class for Scrape requests
  #
  module ScrapeRequestCore
    autoload :SignedUrl, 'monkeyshines/scrape_request/signed_url'

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

    BAD_CHARS = { "\r" => "&#13;", "\n" => "&#10;", "\t" => "&#9;" }
    # BAD_CHARS = { "\r" => "\n!!cr!!\n", "\n" => "\n!!newl!!\n", "\t" => "\n!!tab!!\n" }
    def response= response
      return unless response
      self.contents = response.body.chomp.gsub(/[\r\n\t]/){|c| BAD_CHARS[c]}
    end

    def url_encode str
      return '' if str.blank?
      str = str.gsub(/ /, '+')
      Addressable::URI.encode_component(str, Addressable::URI::CharacterClasses::UNRESERVED+'+')
    end

    def key
      [self.class, Digest::MD5.hexdigest(self.url)].join("-")
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
