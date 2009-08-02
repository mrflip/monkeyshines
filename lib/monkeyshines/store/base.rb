module Monkeyshines
  module Store
    class Base
      def initialize options={}
        Monkeyshines.logger.info "Opening #{self.class.to_s}"
      end

      #
      def each_as klass, &block
        self.each do |*args|
          begin
            item = klass.new *args[1..-1]
          rescue Exception => e
            p [args, self, e.to_s]
            raise e
          end
          yield item
        end
      end

    end
  end
end
