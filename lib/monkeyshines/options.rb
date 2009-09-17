require 'monkeyshines/utils/trollop'
module Monkeyshines

  CMDLINE_OPTIONS = [
    [:handle,          "Identifying string for scrape",     { :type => String, :required => true } ],
    [:source_filename, "URI for scrape store to load from", { :type => String                    } ],
    [:dest_filename,   "Filename for results",              { :type => String                    } ],
    [:log_dest,        "Log file location",                 { :type => String                    } ],
  ]

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
        CONFIG.deep_merge!( all_defaults[key] || {} )
      end
    end
  end


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
    cmdline = self.get_cmdline_args
    cmdline.each do |key, val|
      next if key.to_s =~ /_given$/
      args = key.to_s.split(/_/).map(&:to_sym)+[val]
      result.deep_set(*args) # if val
    end
    result[:handle] = result[:handle].to_s.gsub(/\W/,'').to_sym
    result
  end

  # Use the trollop options defined in Monkeyshines::CMDLINE_OPTIONS
  # to extract command-line args
  def self.get_cmdline_args
    cmdline = Trollop::Parser.new
    Monkeyshines::CMDLINE_OPTIONS.each do |args|
      cmdline.opt *args
    end
    Trollop::do_parse_args(cmdline)
  end

end
