require 'monkeyshines/runner'

module Monkeyshines
  class RecursiveRunner < Monkeyshines::Runner

    def bookkeep result
      super result
      if result
        result.req_generation = result.req_generation.to_i
        return if (result.req_generation >= 2)
        result.recursive_requests do |rec_req|
          rec_req.req_generation = (result.req_generation + 1)
          source.put rec_req
        end
      end
    end

  end
end
