module Monkeyshines
  module RequestStream

    class FlatFileRequestStream < Monkeyshines::RequestStream::Base
      attr_accessor :filename
      def initialize filename, *args
        self.filename = filename
        super *args
      end

      def file
        @file ||= File.open(filename)
      end

      def skip! n_lines
        Monkeyshines.logger.info "Skipping #{n_lines} in #{self.class}:#{filename}"
        n_lines.times do
          file.readline
        end
      end

      def each &block
        file.each do |line|
          attrs = line.chomp.split("\t")
          next if attrs.blank?
          yield request_klass.new(*attrs)
        end
      end
    end

  end
end
