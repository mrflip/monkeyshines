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
            Monkeyshines.logger.info [args, e.to_s, self].join("\t")
            raise e
          end
          yield item
        end
      end

      def log_line
        nil
      end

    end
  end
end
