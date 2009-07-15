require 'fileutils'; include FileUtils

module Monkeyshines
  module ScrapeStore
    #
    class FlatFileStore
      attr_accessor :filename

      #
      # +filename_root+  : first part of name for files
      #
      def initialize filename
        self.filename = filename
      end

      #
      # Open the timestamped file,
      # ensuring its directory exists
      #
      def dump_file
        return @dump_file if @dump_file
        mkdir!
        @dump_file = File.open(filename, "a")
      end
      # Close the dump file
      def close!
        @dump_file.close if @dump_file
        @dump_file = nil
      end
      # Ensure the dump_file's directory exists
      def mkdir!
        FileUtils.mkdir_p File.dirname(filename)
      end
      # write to the dump_file
      def <<(obj)
        dump_file << obj.to_flat.join("\t")+"\n"
      end

    end
  end
end
