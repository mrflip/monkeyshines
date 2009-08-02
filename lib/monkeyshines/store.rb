module Monkeyshines
  module Store
    autoload :Base,                 'monkeyshines/store/base'
    autoload :FlatFileStore,        'monkeyshines/store/flat_file_store'
    autoload :ChunkedFlatFileStore, 'monkeyshines/store/chunked_flat_file_store'
    autoload :KeyStore,             'monkeyshines/store/key_store'
    autoload :TokyoTdbKeyStore,     'monkeyshines/store/tokyo_tdb_key_store'
    autoload :TyrantTdbKeyStore,    'monkeyshines/store/tyrant_tdb_key_store'
    autoload :TyrantHdbKeyStore,    'monkeyshines/store/tyrant_hdb_key_store'
    autoload :ReadThruStore,        'monkeyshines/store/read_thru_store'
  end
end

