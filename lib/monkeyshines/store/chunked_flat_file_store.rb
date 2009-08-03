module Monkeyshines
  module Store
    class ChunkedFlatFileStore < Monkeyshines::Store::FlatFileStore
      attr_accessor :filename_pattern, :chunk_monitor

      DEFAULT_OPTIONS = {
        :time_interval     => 4*60*60, # default 4 hours
      }

      def initialize options
        options = DEFAULT_OPTIONS.merge options
        raise "You don't really want a chunk time this small: #{options[:time_interval]}" unless options[:time_interval] > 600
        self.chunk_monitor    = Monkeyshines::Monitor::PeriodicMonitor.new(options.slice(:time_interval))
        self.filename_pattern = options[:filename_pattern]
        super options.merge(:filename => filename_pattern.make())
        self.mkdir!
      end

      def save *args
        super *args
        chunk_monitor.periodically do
          new_filename = filename_pattern.make()
          Monkeyshines.logger.info "Rotating chunked file #{filename} into #{new_filename}"
          self.close
          @filename = new_filename
          self.mkdir!
        end
      end

    end
  end
end
