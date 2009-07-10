require 'logger'

module Monkeyshines
  autoload :RequestStream,         'monkeyshines/request_stream'
  autoload :FlatFileRequestStream, 'monkeyshines/request_stream'
  autoload :ScrapeStore,           'monkeyshines/scrape_store'

  def self.logger
    @logger ||= Logger.new STDERR
  end
  def self.logger= logger
    @logger = logger
  end

  LOG_INTERVAL = { }
  LOG_COUNTER  = { }
  #
  def self.log_every interval, tracking_token, options={}
    LOG_INTERVAL[tracking_token] = interval
    LOG_COUNTER[ tracking_token] = options[:starting_at] || 0
  end

  def self.log_occasional tracking_token, &block
    if ((LOG_COUNTER[tracking_token] += 1) % LOG_INTERVAL[tracking_token] == 0)
      logger.info block.call(LOG_COUNTER[tracking_token])
    end
  end
end
