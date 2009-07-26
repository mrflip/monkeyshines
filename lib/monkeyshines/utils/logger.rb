require 'logger'
module Monkeyshines
  # Common logger
  def self.logger
    @logger ||= Logger.new STDERR
  end
  def self.logger= logger
    @logger = logger
  end
end
