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
      self.response_code = response.code
      self.contents      = response.body
    end
  end
end
