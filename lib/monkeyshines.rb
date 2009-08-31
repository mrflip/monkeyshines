require 'monkeyshines/extensions'
require 'monkeyshines/utils/logger'
require 'wukong'
require 'wukong/extensions/pathname'
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
  autoload :Runner,                'monkeyshines/runner'
  autoload :RawJsonContents,       'monkeyshines/scrape_request/raw_json_contents'

  # Dumping ground for configuration values
  CONFIG = {} unless defined?(CONFIG)

end

#
# A convenient logger.
#
# Define NO_MONKEYSHINES_LOG (or define Log yourself) to prevent its creation
#
Log = Monkeyshines.logger unless (defined?(Log) || defined?(NO_MONKEYSHINES_LOG))
