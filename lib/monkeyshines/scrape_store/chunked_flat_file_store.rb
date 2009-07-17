module Monkeyshines
  module ScrapeStore
    class ChunkedFlatFileStore < Monkeyshines::ScrapeStore::FlatFileStore
      attr_accessor :filename_pattern, :chunk_monitor

      def initialize filename_pattern, time_interval=nil, *args
        time_interval ||= 4*60*60 # default 4 hours
        self.chunk_monitor    = Monkeyshines::Monitor::PeriodicMonitor.new(:time_interval => time_interval)
        self.filename_pattern = filename_pattern
        super filename_pattern.make(), *args
      end

      def save *args
        super *args
        chunk_monitor.periodically do
          new_filename = filename_pattern.make()
          Monkeyshines.logger.info "Rotating chunked file #{filename} into #{new_filename}"
          self.close!
          @filename = new_filename
        end
      end

    end
  end
end
