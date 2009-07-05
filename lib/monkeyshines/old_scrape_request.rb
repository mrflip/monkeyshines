#
#
# REMEMBER TO ADD ITERATION TO scrape_requests
# move public feed to http://twitter.com/statuses/public_timeline
# tier the ripd/ directories
#
module TwitterFriends::Scrape

  #
  # This is a giant messy POS.
  #
  class OldScrapeRequest < Struct.new( :context, :priority, :identifier, :page, :moreinfo )
    include TwitterFriends::StructModel::ModelCommon

    def initialize context, priority, identifier, page, moreinfo
      priority = "%010d" % priority.to_i
      super context, priority, identifier, page, moreinfo
    end
    # #
    # # Create a ScrapeRequest from a URI string.
    # #
    # def self.new_from_uri uri_str, scraped_at
    #   m = GROK_URI_RE.match(uri_str)
    #   unless m then warn "Can't grok uri #{uri_str}"; return nil; end
    #   resource, identifier, page = m.captures
    #   context = context_for_resource(resource)
    #   self.new identifier, context, page, scraped_at
    # end

    def self.pages thing, context
      case context
      # when :favorites  then count = thing.favourites_count ; per_page = 20
      when :friends    then
        new_friends = (thing.friends_per_day * thing.days_since_scraped) * 3
        count       = [new_friends, 5000].min
        per_page    = 100
      else raise "need to define pages for context #{context}"
      end
      [ (count.to_f / per_page.to_f).ceil, 1 ].max
    end

    def self.gen_priority thing, context
      case context
      when :favorites  then pages(thing, context)
      when :friends    then [ (100 * thing.friends_per_day).to_i, 1 ].max
      else raise "need to define priority for context #{context}"
      end
    end

    def self.resource_name
      class_part = super
      [class_part, context].join("-")
    end

    def self.keyspace_spread_resource_name
      [self.resource_name, identifier].join("-") #
    end

    def self.requests_for_user user, context
      return [] if user.send("#{context}_count").blank?
      return [] if (context == :favorites) && user.favourites_count.to_i < 10
      (1..pages(user, context)).map do |page|
        new context, gen_priority(user, context), user.screen_name, "%05d"%[page], user.id
        # [user.id, pages(user, context), user.created_at, user.friends_per_day, user.days_since_scraped].join('-')
      end
    end

  end
end
