module Monkeyshines
  module RequestStream

    #
    # RequestStream::Base
    #
    # base just instantiates options[:klass] on each element of the
    # options[:store]
    #
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

    end
  end
end
