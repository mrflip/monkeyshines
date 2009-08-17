module Monkeyshines
  module Fetcher
    extend FactoryModule
    autoload :Base,            'monkeyshines/fetcher/base'
    autoload :FakeFetcher,     'monkeyshines/fetcher/fake_fetcher'
    autoload :HttpFetcher,     'monkeyshines/fetcher/http_fetcher'
    autoload :HttpHeadFetcher, 'monkeyshines/fetcher/http_head_fetcher'

  end
end
