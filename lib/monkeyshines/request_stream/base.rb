module Monkeyshines
  module RequestStream

    class Base
      attr_accessor :request_klass
      attr_accessor :request_store
      def initialize options={}
        self.request_klass = options[:klass]
        self.request_store = Monkeyshines::Store.create(options[:store])
      end

      def each *args, &block
        self.request_store.each(*args) do |req_params|
          yield request_klass.new(req_params)
        end
      end

      # def self.new_from_command_line cmdline_opts, default_opts={}
      #   options = default_opts.merge(cmdline_opts)
      #   Trollop::die :from, "is required: location of scrape request stream" if options[:from].blank?
      #   request_stream = Monkeyshines::FlatFileRequestStream.new(options[:from], options[:request_klass])
      #   request_stream.skip! options[:skip] if options[:skip].to_i > 0
      #   request_stream
      # end

    end
  end
end
