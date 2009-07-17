require 'fileutils'; include FileUtils

module Monkeyshines
  module ScrapeStore
    #
    class FlatFileStore
      attr_accessor :filename

      #
      # +filename_root+  : first part of name for files
      #
      def initialize filename, options={}
        self.filename = filename
      end

      #
      # Open the timestamped file,
      # ensuring its directory exists
      #
      def dump_file
        return @dump_file if @dump_file
        mkdir!
        Monkeyshines.logger.info "Opening file #{filename} for appending"
        @dump_file = File.open(filename, "a")
      end
      # Close the dump file
      def close!
        @dump_file.close if @dump_file
        @dump_file = nil
      end
      # Ensure the dump_file's directory exists
      def mkdir!
        dir = File.dirname(filename)
        return if File.directory?(dir)
        Monkeyshines.logger.info "Making directory #{dir}"
        FileUtils.mkdir_p dir
      end
      # write to the dump_file
      def <<(obj)
        dump_file << obj.to_flat.join("\t")+"\n"
      end
      # delegates to +<<()+ -- writes the object to the file
      def save obj
        self << obj
      end
    end

  end
end

