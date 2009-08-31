module Monkeyshines
  # Common logger
  def self.logger
    @logger ||= Monkeyshines.default_logger
  end
  def self.logger= logger
    @logger = logger
  end

  def self.default_logger dest=nil
    require 'logger'
    dest ||= $stderr
    Logger.new dest
  end
end
