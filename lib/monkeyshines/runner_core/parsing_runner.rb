require 'yaml'
require 'monkeyshines/runner_core/options'

module Monkeyshines

  #
  # In general, you should
  #
  # But where an external library is alread providing cooked results or it's
  # otherwise most straightforward to directly emit model objects, you can use
  # a parsing runner
  #
  class ParsingRunner < Runner

    #
    # Fetch and store result
    #
    #
    def fetch_and_store req
      result = fetcher.get(req)       # do the url fetch
      # results.each do |result|
        result.parse do |obj|
          dest.save(obj)
        end
    #end
    end

  end
end
