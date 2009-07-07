require 'fileutils'; include FileUtils

module Monkeyshines
  module ScrapeStore
    #
    class FlatFileStore
      CHECKPOINT_INTERVAL = 15*60 unless defined?(TwitterFriends::Scrape::ScrapeDumper::CHECKPOINT_INTERVAL)
      attr_accessor :filename_root, :dump_file
      attr_accessor :timestamp

      #
      # +filename_root+  : first part of name for files
      #
      def initialize filename_root
        self.filename_root = filename_root
      end

      #
      # Open the timestamped file,
      # ensuring its directory exists
      #
      def open!
        mkdir!
        self.dump_file = File.open(dump_filename, "a")
      end
      # Ensure the dump_file's directory exists
      def mkdir!
        FileUtils.mkdir_p File.dirname(dump_filename)
      end
      # Close the dump file
      def close!
        dump_file.close if dump_file
      end
      # write to the dump_file
      def <<(s)
        dump_file << s
      end
      #
      def set request
        checkpoint!
        self << request.to_flat
      end

      #
      # Handle checkpointing:
      # occasionally close current dump file and open new one
      #
      def stale?
        return true unless timestamp
        return true unless dump_file
        (Time.now - timestamp > CHECKPOINT_INTERVAL)
      end

      #
      # If the dump_file has never been opened, or if it's time to close the old
      # and open the new:
      #
      # closes the old dump_file, if any;
      # adopts a new timestamp
      # opens a dump_file ready for writing
      #
      def checkpoint!
        return unless stale?
        close!
        self.timestamp = Time.now
        @dump_filename = nil
        open!
      end

      #
      # Filename for dump
      #
      def dump_filename
        @dump_filename ||= File.join(ripd_dir, date_slug, dump_filename_filepart)
      end
      # file part
      def dump_filename_filepart
        t_str = timestamp.strftime(DATEFORMAT)
        "#{handle}+#{t_str}.scrape.tsv"
      end
      # directory cascade to prevent filesystem issues
      # (They don't like more than a few thousand files in each directory)
      def date_slug
        timestamp.strftime("_%Y%m%d/_%H")
      end

    end
  end
end
