require 'monkeyshines/utils/trollop'
module Monkeyshines
  class Runner

    def self.load_cmdline_options!
      Monkeyshines::CONFIG.deep_merge! options_from_cmdline
    end
    
    #
    # Takes the values set on the command line
    # and merges them into the options hash:
    #   --source-filename
    # sets the value for options[:source][:filename], etc.
    #
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
    
    # Let all the participants inject trollop command-line arguments
    def self.get_cmdline_args
      cmdline = Trollop::Parser.new
      self.define_cmdline_options do |*args|
        cmdline.opt *args
      end
      Trollop::do_parse_args(cmdline)
    end

    def self.define_cmdline_options &block
      yield :handle,          "Identifying string for scrape",     :type => String, :required => true
      yield :source_filename, "URI for scrape store to load from", :type => String
      yield :dest_filename,   "Filename for results",              :type => String
      yield :log_dest,        "Log file location",                 :type => String
      # yield :dest_cache_uri,  "URI for cache server",              :type => String
    end

  end
end
