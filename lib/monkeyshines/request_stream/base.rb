module Monkeyshines
  module RequestStream

    #
    # RequestStream::Base
    #
    # base just instantiates options[:klass] on each element of the
    # options[:store]
    #
    class Base
      attr_accessor :options
      attr_accessor :request_store
      def initialize options={}
        self.options       = options
        self.request_store = Monkeyshines::Store.create(options[:store])
      end

      def request_for_params *params
        options[:klass].new(params)
      end

      def each *args, &block
        self.request_store.each(*args) do |*params|
          yield request_for_params(*params)
        end
      end

    end
  end
end
