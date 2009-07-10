module Monkeyshines
  module ScrapeStore
    class Base
      def initialize
        Monkeyshines.logger.info "Opening #{self.class.to_s}"
      end
    end
  end
end
