module Monkeyshines
  module ScrapeStore
    autoload :Base,                 'monkeyshines/scrape_store/base'
    autoload :FlatFileStore,        'monkeyshines/scrape_store/flat_file_store'
    autoload :ChunkedFlatFileStore, 'monkeyshines/scrape_store/chunked_flat_file_store'
    autoload :KeyStore,             'monkeyshines/scrape_store/key_store'
    autoload :TokyoTdbKeyStore,     'monkeyshines/scrape_store/tokyo_tdb_key_store'
    autoload :TyrantTdbKeyStore,    'monkeyshines/scrape_store/tyrant_tdb_key_store'
    autoload :ReadThruStore,        'monkeyshines/scrape_store/read_thru_store'
  end
end

