require 'monkeyshines/runner'

module Monkeyshines
  class RecursiveRunner < Monkeyshines::Runner
    GENERATION_LIMIT = 5

    #
    # Generate requests that ensue from this one
    #
    # if GENERATION_LIMIT is 5, requests at generation 4 *do* generate recursive
    # jobs, ones at generation 5 do not (so, generation 6 shouldn't exist)
    #
    def bookkeep result
      super result
      if result
        result.req_generation = result.req_generation.to_i
        return if (result.req_generation >= GENERATION_LIMIT)
        iter = 0
        result.recursive_requests do |rec_req|
          source.put rec_req
        end
      end
    end

  end
end
