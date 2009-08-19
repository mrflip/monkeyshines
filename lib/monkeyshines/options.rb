require 'trollop'
module Monkeyshines
  #
  # Load the YAML file ~/.monkeyshines
  # and toss it into Monkeyshines::CONFIG
  #
  def self.load_global_options! *keys
    all_defaults = YAML.load(File.open(ENV['HOME']+'/.monkeyshines'))
    if keys.blank?
      CONFIG.deep_merge! all_defaults
    else
      keys.each do |key|
        CONFIG.deep_merge! all_defaults[key]
      end
    end
  end

  def self.load_cmdline_options!
    CONFIG.deep_merge! options_from_cmdline
  end

  def self.options_from_cmdline
    result = {}
    cmdline = get_cmdline_args
    cmdline.each do |key, val|
      next if key.to_s =~ /_given$/
      args = key.to_s.split(/_/).map(&:to_sym)+[val]
      result.deep_set(*args) # if val
    end
    result[:handle] = result[:handle].to_sym if (! result[:handle].blank?)
    result
  end

  def self.get_cmdline_args
    cmdline = Trollop::options do
      opt :handle,          "Identifying string for scrape",     :type => String, :required => true
      opt :source_filename, "URI for scrape store to load from", :type => String
      opt :dest_filename,   "Filename for results",              :type => String
      # opt :dest_cache_uri,  "URI for cache server",              :type => String
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
