module Monkeyshines
  module ScrapeStore
    autoload :Base, 'monkeyshines/scrape_store/base'
    autoload :FlatFileStore, 'monkeyshines/scrape_store/flat_file_store'
    autoload :ChunkedFlatFileStore, 'monkeyshines/scrape_store/chunked_flat_file_store'
  end
end

