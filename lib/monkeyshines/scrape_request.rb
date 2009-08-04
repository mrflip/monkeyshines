module Monkeyshines

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
  # Base class for Scrape requests
  #
  module ScrapeRequestCore
    #
    def healthy?
      (! url.blank) && (            # has a URL and either:
        scraped_at.blank?        || # hasn't been scraped,
        (! response_code.blank?) || # or has, with response code
        (! contents.blank?) )       # or has, with response
    end

    # Set URL from other attributes
    def make_url!
      self.url = make_url
    end

    BAD_CHARS = { "\r" => "&#13;", "\n" => "&#10;", "\t" => "&#9;" }
    def response= response
      return unless response
      self.contents = response.body.gsub(/[\r\n\t]/){|c| BAD_CHARS[c]}
    end
  end

end
