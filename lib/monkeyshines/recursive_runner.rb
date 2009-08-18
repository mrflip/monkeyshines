require 'monkeyshines/runner'

module Monkeyshines
  class RecursiveRunner < Monkeyshines::Runner

    def bookkeep result
      super result
      result.recursive_requests do |rec_req|
        source.put rec_req
      end
    end

  end
end
