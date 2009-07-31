module Monkeyshines
  module RequestStream

    class Base
      attr_accessor :request_klass
      attr_accessor :request_store
      def initialize request_klass, request_store, options={}
        self.request_klass = request_klass
        self.request_store = request_store
      end

      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        Trollop::die :from, "is required: location of scrape request stream" if options[:from].blank?
        request_stream = Monkeyshines::FlatFileRequestStream.new(options[:from], options[:request_klass])
        request_stream.skip! options[:skip] if options[:skip].to_i > 0
        request_stream
      end

      def each *args, &block
        self.request_store.each(*args) do |req_params|
          yield request_klass.new(req_params)
        end
      end
    end

  end
end
