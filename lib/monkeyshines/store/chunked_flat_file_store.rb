module Monkeyshines
  module Store
    class ChunkedFlatFileStore < Monkeyshines::Store::FlatFileStore
      attr_accessor :filename_pattern, :chunk_monitor

      DEFAULT_OPTIONS = {
        :time    => 4*60*60, # default 4 hours
      }

      def initialize options
        options = DEFAULT_OPTIONS.merge options
        raise "You don't really want a chunk time this small: #{options[:time]}" unless options[:time] > 600
        self.chunk_monitor    = Monkeyshines::Monitor::PeriodicMonitor.new(options.slice(:time))
        self.filename_pattern = options[:filename_pattern] ||
          Monkeyshines::Utils::FilenamePattern.new(options[:dest_pattern], :handle => options[:handle], :dest_dir => options[:dest_dir])
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
