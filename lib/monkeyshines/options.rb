require 'monkeyshines/utils/trollop'
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

  # Let all the participants inject trollop command-line arguments
  def self.get_cmdline_args
    cmdline = Trollop::Parser.new
    Monkeyshines::Runner.define_cmdline_options do |*args|
      cmdline.opt *args
    end
    Trollop::do_parse_args(cmdline)
  end

end
