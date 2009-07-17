module Monkeyshines
  module RequestStream

    class Base
      attr_accessor :request_klass
      def initialize request_klass, options={}
        self.request_klass = request_klass
      end

      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        Trollop::die :from, "is required: location of scrape request stream" if options[:from].blank?
        request_stream = Monkeyshines::FlatFileRequestStream.new(options[:from], options[:request_klass])
        request_stream.skip! options[:skip] if options[:skip].to_i > 0
        request_stream
      end
    end

  end
end
