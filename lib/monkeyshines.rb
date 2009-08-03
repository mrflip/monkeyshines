require 'monkeyshines/extensions'
require 'monkeyshines/request_stream'
require 'monkeyshines/utils/logger'
require 'monkeyshines/utils/factory_module'

module Monkeyshines
  autoload :RequestStream,         'monkeyshines/request_stream'
  autoload :FlatFileRequestStream, 'monkeyshines/request_stream'
  autoload :Store,                 'monkeyshines/store'
  autoload :Fetcher,               'monkeyshines/fetcher'
  autoload :Monitor,               'monkeyshines/monitor'

  # Dumping ground for configuration values
  CONFIG = {} unless defined?(CONFIG)
end
