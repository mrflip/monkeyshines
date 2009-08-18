require 'wukong'
require "wukong/extensions/pathname"
require 'monkeyshines/extensions'
require 'monkeyshines/utils/logger'
require 'monkeyshines/utils/factory_module'
require 'monkeyshines/utils/uri'
require 'monkeyshines/utils/filename_pattern'
require 'monkeyshines/options'
require 'monkeyshines/scrape_request'

module Monkeyshines
  autoload :ScrapeRequest,         'monkeyshines/scrape_request'
  autoload :ScrapeRequestCore,     'monkeyshines/scrape_request'
  autoload :RequestStream,         'monkeyshines/request_stream'
  autoload :Store,                 'monkeyshines/store'
  autoload :Fetcher,               'monkeyshines/fetcher'
  autoload :Monitor,               'monkeyshines/monitor'

  # Dumping ground for configuration values
  CONFIG = {} unless defined?(CONFIG)

  #
  # Load the YAML file ~/.monkeyshines
  # and toss it into Monkeyshines::CONFIG
  #
  def self.load_global_defaults! *keys
    all_defaults = YAML.load(File.open(ENV['HOME']+'/.monkeyshines'))
    if keys.blank?
      CONFIG.deep_merge! all_defaults
    else
      keys.each do |key|
        CONFIG.deep_merge! all_defaults[key]
      end
    end
  end
end
