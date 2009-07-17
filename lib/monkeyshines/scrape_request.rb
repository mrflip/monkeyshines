module Monkeyshines
  # class ScrapeRequestGroup
  #   attr_accessor :http_scraper, :thing
  #   def initialize thing
  #     self.http_scraper = HTTPScraper.new('twitter.com')
  #     self.thing = thing
  #   end
  # end

  class ScrapeRequest < Struct.new(
    :url,
    :scraped_at,
    :response_code, :response_message,
    :contents
      )
    def response= response
      return unless response
      self.response_code    = response.code
      self.response_message = response.message[0..200].gsub(/[\n\r\t]+/, ' ')
      self.contents         = response.body
    end

    # Checks that the response parses and has the right data structure.
    # if healthy? is true things should generally work
    def healthy?
    end

    #
    # by default, just returns the contents
    def parsed_response
      contents
    end

    # Lets a scrape_request act as its own session
    def each_request pageinfo={}, &block
      yield self
    end
  end
end
