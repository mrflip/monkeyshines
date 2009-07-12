#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyocabinet'
module Monkeyshines
  module ScrapeStore
    class ReadThruStore < Monkeyshines::ScrapeStore::Base
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :db

      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri, create_db=false, *args
        super *args
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
        db.put(key, result.to_hash)
      end

      # Delegate to store
      def get(key)    db[key]  end
      def [](key)     db[key]  end
      def close()     db.close end
      def size()      db.size  end

      #
      # Load standard command-line options
      #
      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        Trollop::die :store_db, "is required: a tokyo cabinet db to store responses" if options[:store_db].blank?
        store = self.new(options[:store_db], options[:create_db])
        Trollop::die :store_db, "isn't a tokyo cabinet DB I could load" unless store.db
        store
      end
    end
  end
end
