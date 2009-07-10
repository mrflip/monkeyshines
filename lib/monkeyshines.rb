require 'monkeyshines/request_stream'
require 'logger'
module Monkeyshines
  def self.logger
    @logger ||= Logger.new STDOUT
  end
  def self.logger= logger
    @logger = logger
  end
end
