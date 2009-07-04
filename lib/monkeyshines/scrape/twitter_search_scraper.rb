require 'active_support/core_ext/class/inheritable_attributes.rb'
class GenericTwitterSearchScraper
  class_inheritable_accessor :source
  cattr_accessor :sleep_interval
  attr_accessor :queries
  self.sleep_interval = 0.25
  ABSOLUTE_MAX_PAGES_PER_QUERY = 1500

  def initialize
    self.queries = []
  end

  def wget query, page
    $stderr.puts [page, query].join("\t")
    url = search_url source, query, page
    cmd = %Q{wget -nv -x '#{url}' }
    $stderr.puts `#{cmd}`
    sleep self.class.sleep_interval
  end


  def rest_get query, page, max_id
    url, params = search_url query, page, max_id
    begin
      response = RestClient.get(url, params)
    rescue Exception => e
      warn "Failed with #{e}"
      sleep sleep_interval
    end
    [response, url]
  end

  def add_urls_file_queries urls_file
    File.open(urls_file) do |f|
      new_queries = f.readlines.map(&:chomp).map{|s| s.split(/\s+/).last}
      new_queries.reject!{|s| (s =~ %r{http://twitter.com/}) || (s !~ %r{http://[^\./]+\.[^/]+/.+}) }
      self.queries += new_queries
    end
  end

  def get_response raw_response
    return unless raw_response
    begin
      response = JSON.load(raw_response.to_s)
    rescue Exception => e
      warn "JSON not parsing : #{e}" ; return nil
    end
    response
  end

  def next_max_id response
    results = get_results(response) or return
    results.last['id']
  end

  def terminate? response, page
    results = get_results(response) or return
    results.length < (max_results_per_page-2)
  end

  def scrape_query dump_file, query, initial_max_id = nil
    page       = 1
    response   = nil
    max_id     = initial_max_id
    old_max_id = max_id
    ABSOLUTE_MAX_PAGES_PER_QUERY.times do |abs_pg|
      raw_response, url = rest_get(query, page, max_id)
      dump_file << [source, query, page, url, raw_response].join("\t")+"\n"
      if ! raw_response
        $stderr.puts "Bad response '#{response}', max_id #{max_id} and page #{page}"
        page += 1
        sleep 2
        next
      end
      begin
        response    = get_response(raw_response)
        results     = get_results(response)
        num_results = results ? results.length : nil
        old_max_id  = max_id
        max_id      = next_max_id(response)
        page        = 1 if max_id
        $stderr.puts [source, query, page, url, response.to_s.length, num_results, old_max_id.to_i - max_id.to_i, abs_pg ].join("\t")
        sleep sleep_interval
      rescue Exception => e ; warn e ; break ; end
      break if terminate?(response, page) || (! max_id)
    end
    $stderr.puts "Finished '#{query}', last seen was id #{max_id}"
  end

  def scrape dump_filename, initial_max_id = nil
    File.open(dump_filename, "w") do |dump_file|
      queries.each do |query|
        scrape_query dump_file, query, initial_max_id
      end
    end
  end
end


class TwitterSearchScraper < GenericTwitterSearchScraper
  attr_accessor :last_response_length
  self.source = :twitter
  def initialize
    super
    self.last_response_length = -1
  end
  def search_url query, page, max_id=nil
    max_id_part = max_id ? "&max_id=#{max_id}" : ""
    %Q{http://search.twitter.com/search.json?q=#{query}&rpp=#{max_results_per_page}&page=#{page}#{max_id_part}}
  end
  def max_results_per_page
    100
  end
  def max_page
    15
  end
  def get_results response
    return unless response
    response['results']
  end
end

class FriendFeedSearchScraper
  def search_url query, page, max_id
    start = (page-1)*100
    %Q{http://friendfeed.com/api/feed/search?q=#{query}&service=twitter&start=#{start}&num=100}
  end
  def max_results_per_page
    100
  end
  def max_page
    4
  end
  def terminate? response, page
    terminate = super || page >= max_page
  end
  def get_results response
    response['entries'] if response
  end
end

# end
