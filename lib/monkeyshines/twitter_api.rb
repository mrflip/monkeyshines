module TwitterApi
  #
  # The URI for a given resource
  #
  def gen_url
    case context
    when :user, :followers, :friends, :favorites, :timeline
      "http://twitter.com/#{resource_path}/#{identifier}.json?page=#{page}"
    when :followers_ids, :friends_ids
      "http://twitter.com/#{resource_path}/#{identifier}.json"
    when :user_timeline
      "http://twitter.com/#{resource_path}/#{identifier}.json?page=#{page}&count=200"
    # when :public_timeline
    # when :search
    #  "http://search.twitter.com/search.json?q=#{query}"
    else
      raise "Don't know how to retrieve #{context} yet"
    end
  end

  # Regular expression to grok resource from uri
  GROK_URI_RE = %r{http://twitter.com/(\w+/\w+)/(\w+)\.json\?page=(\d+)}

  # Context <=> resource mapping
  #
  # aka. repairing the non-REST uri's
  RESOURCE_PATH_FROM_CONTEXT = {
    :user            => 'users/show',
    :followers_ids   => 'followers/ids',
    :friends_ids     => 'friends/ids',
    :followers       => 'statuses/followers',
    :friends         => 'statuses/friends',
    :favorites       => 'favorites',
    :timeline        => 'statuses/user_timeline',
    :user_timeline   => 'statuses/user_timeline',
    :public_timeline => 'statuses/public_timeline'
  }
  # Get url resource for context
  def resource_path
    RESOURCE_PATH_FROM_CONTEXT[context.to_sym]
  end

  def self.pages_from_count per_page, count, max=nil
    num = [ (count.to_f / per_page.to_f).ceil, 0 ].max
    [num, max].compact.min
  end
  def self.pages context, thing
    case context
    when :favorites       then pages_from_count( 20, thing.favourites_count, 20)
    when :friends         then pages_from_count(100, thing.friends_count,    10)
    when :followers       then pages_from_count(100, thing.followers_count,  10)
    when :followers_ids   then thing.followers_count == 0 ? 0 : 1
    when :friends_ids     then thing.friends_count   == 0 ? 0 : 1
    when :user            then 1
    when :public_timeline then 1
    when :user_timeline   then pages_from_count(200, thing.statuses_count,   20)
    when :search          then pages_from_count(100, 1500)
    else raise "need to define pages for context #{context}"
    end
  end

  module ClassMethods
    # Get context from url resource
    def context_for_resource(resource)
      RESOURCE_PATH_FROM_CONTEXT.invert[resource] or raise("Wrong resource specification #{resource}")
    end
  end

  def self.included base
    base.extend ClassMethods
  end
end

# language: http://en.wikipedia.org/wiki/ISO_639-1
#
# * Find tweets containing a word:         http://search.twitter.com/search.atom?q=twitter
# * Find tweets from a user:               http://search.twitter.com/search.atom?q=from%3Aalexiskold
# * Find tweets to a user:                 http://search.twitter.com/search.atom?q=to%3Atechcrunch
# * Find tweets referencing a user:        http://search.twitter.com/search.atom?q=%40mashable
# * Find tweets containing a hashtag:      http://search.twitter.com/search.atom?q=%23haiku
# * Combine any of the operators together: http://search.twitter.com/search.atom?q=movie+%3A%29
#
# * lang:      restricts tweets to the given language, given by an ISO 639-1 code. Ex: http://search.twitter.com/search.atom?lang=en&q=devo
# * rpp:       the number of tweets to return per page, up to a max of 100. Ex: http://search.twitter.com/search.atom?lang=en&q=devo&rpp=15
# * page:      the page number (starting at 1) to return, up to a max of roughly 1500 results (based on rpp * page)
# * since_id:  returns tweets with status ids greater than the given id.
# * geocode:   returns tweets by users located within a given radius of the given latitude/longitude, where the user's location is taken from their Twitter profile. The parameter value is specified by "latitide,longitude,radius", where radius units must be specified as either "mi" (miles) or "km" (kilometers). Ex: http://search.twitter.com/search.atom?geocode=40.757929%2C-73.985506%2C25km. Note that you cannot use the near operator via the API to geocode arbitrary locations; however you can use this geocode parameter to search near geocodes directly.
# * show_user: when "true", adds "<user>:" to the beginning of the tweet. This is useful for readers that do not display Atom's author field. The default is "false".
