require 'monkeyshines/extensions'
require 'monkeyshines/utils/logger'
require 'monkeyshines/utils/factory_module'

module Monkeyshines
  autoload :ScrapeRequest,         'monkeyshines/scrape_request'
  autoload :ScrapeRequestCore,     'monkeyshines/scrape_request'
  autoload :RequestStream,         'monkeyshines/request_stream'
  autoload :Store,                 'monkeyshines/store'
  autoload :Fetcher,               'monkeyshines/fetcher'
  autoload :Monitor,               'monkeyshines/monitor'

  # Dumping ground for configuration values
  CONFIG = {} unless defined?(CONFIG)
end
