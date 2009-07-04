module TwitterFriends::Scrape
  class ScrapeRequestGroup
    attr_accessor :http_scraper, :thing
    def initialize thing
      self.http_scraper = HTTPScraper.new('twitter.com')
      self.thing = thing
    end
  end

  class ScrapeRequest < Struct.new(
      :context, :priority, :identifier, :page, :moreinfo,
      :url,
      :scraped_at, :response_code, :response_message,
      :contents )
    include TwitterFriends::StructModel::ModelCommon

    def dump_form
      line = to_a.join("\t")
      line.gsub!(/[\r\n]+/, ' ')
      line+"\n"
    end


    def gen_priority() 1 end

    #
    def num_key_fields()        4     end
    def numeric_id_fields()     []    end

    def key
      rev_priority = 1e9 - priority.to_i
      rev_priority = 1 if rev_priority <= 1
      "%-60s"% ([context, "%010d"%rev_priority, identifier, "%010d"%page.to_i].join("-"))
    end
    #
    #
    def self.keyspace_spread_resource_name
      [self.resource_name, identifier].join("-") #
    end

  end

  class RetryRequest < ScrapeRequest
  end
end
