module Monkeyshines
  module RequestStream

    #
    # KlassRequestStream is an abstract factory for requests -- the first arg
    # gives the request type
    #
    class KlassRequestStream < Base
      attr_accessor :request_store
      attr_accessor :klass_scope
      KlassRequestStream::DEFAULT_OPTIONS = {
        :store       => { :type => :flat_file_store },
        :klass_scope => Kernel,
      }
      def initialize _options={}
        super KlassRequestStream::DEFAULT_OPTIONS.merge(_options)
        self.request_store = Monkeyshines::Store.create(options.merge(options[:store]))
        self.klass_scope   = options[:klass_scope]
      end
      #
      # use the first arg as a klass name
      # to create a scrape request using rest of args
      #
      def request_from_raw klass_name, *raw_req_args
        klass = FactoryModule.get_class(klass_scope, klass_name)
        klass.new(*raw_req_args)
      end
    end

    class KlassHashRequestStream < KlassRequestStream
      def request_from_raw klass_name, hsh
        klass = FactoryModule.get_class(klass_scope, klass_name)
        klass.from_hash(hsh)
      end
    end

  end
end

