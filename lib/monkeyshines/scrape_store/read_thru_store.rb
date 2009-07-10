#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyocabinet'
module Monkeyshines
  module ScrapeStore
    class ReadThruStore
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :db

      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri, create_db=false
        self.db = TokyoCabinet::TDB.new
        # connect to the db or nil out the db object
        flags = TokyoCabinet::TDB::OWRITER
        flags = flags | TokyoCabinet::TDB::OCREAT if create_db
        self.db.open(db_uri, flags) or self.db = nil
      end

      #
      # If key is absent, save the result of calling the block.
      # If key is present, block is never called.
      #
      # Ex:
      #   rt_store.set(url) do
      #     scraper.get url # will only be called if url isn't in rt_store
      #   end
      #
      def set key, &block
        return if db.include?(key)
        result = block.call() or return
        db.putasync(key, result.to_a.join("\t"))
      end

      # Delegate to store
      def get(key)    db[key]  end
      def [](key)     db[key]  end
      def close()     db.close end
    end
  end
end
