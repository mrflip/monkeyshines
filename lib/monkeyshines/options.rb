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
end
