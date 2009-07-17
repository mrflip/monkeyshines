require 'logger'
require 'monkeyshines/extensions'
require 'monkeyshines/request_stream'

module Monkeyshines
  autoload :RequestStream,         'monkeyshines/request_stream'
  autoload :FlatFileRequestStream, 'monkeyshines/request_stream'
  autoload :ScrapeStore,           'monkeyshines/scrape_store'
  autoload :ScrapeEngine,          'monkeyshines/scrape_engine'
  autoload :Monitor,               'monkeyshines/monitor'

  # Dumping ground for configuration values
  CONFIG = {} unless defined?(CONFIG)

  # Common logger
  def self.logger
    @logger ||= Logger.new STDERR
  end
  def self.logger= logger
    @logger = logger
  end

  OCCASIONAL_LOG_INTERVAL = { }
  OCCASIONAL_LOG_COUNTER  = { }
  #
  # Sets up interval and starting value for log_occasional
  #
  # options[:every] sets how often the log is written
  # options[:starting_at] sets an initial value for the iteration
  #
  #
  def self.log_occasional_begin tracking_token, options={}
    OCCASIONAL_LOG_INTERVAL[tracking_token] = options[:every]       || 100
    OCCASIONAL_LOG_COUNTER[ tracking_token] = options[:starting_at] || 0
  end

  #
  # Using values set in log_occasional_begin.
  # Logs every N'th time this is called with the corresponding token.
  #
  # If N calls have passed, calls &block with the (pos-increment) iterator as
  # argument.
  #
  # Ex.
  #     log_occasional_begin :requests, :every => 100, :starting_at => resume_point||0
  #     loop do
  #       # ... stuff ...
  #       log_occasional(:requests){|iter| [iter, request.url, result.length].join("\t") }
  #     end
  #
  def self.log_occasional tracking_token, &block
    if ((OCCASIONAL_LOG_COUNTER[tracking_token] += 1) % OCCASIONAL_LOG_INTERVAL[tracking_token] == 0)
      result = block.call(OCCASIONAL_LOG_COUNTER[tracking_token])
      logger.info result
    end
  end
end
