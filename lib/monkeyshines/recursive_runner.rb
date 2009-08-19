require 'monkeyshines/runner'

module Monkeyshines
  class RecursiveRunner < Monkeyshines::Runner

    def bookkeep result
      super result
      if result
        result.req_generation = result.req_generation.to_i
        return if (result.req_generation >= 5)
        iter = 0
        result.recursive_requests do |rec_req|
          source.put rec_req
          # break if (iter+=1) > 5
        end
      end
    end

  end
end
