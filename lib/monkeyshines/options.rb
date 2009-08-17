module Monkeyshines
  module Options

    def self.get_cmdline_args
      cmdline = Trollop::options do
        opt :source_filename, "URI for scrape store to load from", :type => String
        opt :dest_filename,   "Filename for results",              :type => String
        # opt :dest_cache_uri,  "URI for cache server",              :type => String
      end
    end
    
    def self.options_from_cmdline 
      result = {}
      cmdline = get_cmdline_args
      cmdline.each do |key, val|
        next if key.to_s =~ /_given$/
        args = key.to_s.split(/_/).map(&:to_sym)+[val]
        result.deep_set(*args) # if val
      end
      result
    end
    
  end
end

class Hash
  def self.deep_sum *args
    args.inject({}) do |result, options|
      result.deep_merge options
    end
  end
end  
