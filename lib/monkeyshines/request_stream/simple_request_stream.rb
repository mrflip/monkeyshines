module Monkeyshines
  module RequestStream

    #
    # SimpleRequestStream generates an instance of options[:klass] from each element of its store
    #
    class SimpleRequestStream < KlassRequestStream
      attr_accessor :klass
      SimpleRequestStream::DEFAULT_OPTIONS = {
        :klass => Monkeyshines::ScrapeRequest,
      }
      def initialize _options={}
        super SimpleRequestStream::DEFAULT_OPTIONS.merge(_options)
        self.klass         = options[:klass]
      end
      def request_from_raw *raw_req_args
        klass.new(*raw_req_args)
      end
    end
    
  end
end
