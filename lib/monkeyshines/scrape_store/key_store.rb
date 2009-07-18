#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyotyrant'
module Monkeyshines
  module ScrapeStore
    class KeyStore < Monkeyshines::ScrapeStore::Base
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :db

      #
      # Executes block once for each element in the whole DB, in whatever order
      # the DB thinks you should see it.
      #
      # Your block will see |key, val|
      #
      # key_store.each do |key, val|
      #   # ... stuff ...
      # end
      #
      def each &block
        db.iterinit
        loop do
          key = db.iternext or break
          val = db[key]
          yield key, val
        end
      end

      def each_as klass, &block
        self.each do |key, hsh|
          yield klass.from_hash hsh
        end
      end

      # Delegate to store
      def set(key, val)
        return unless val
        db.put key, val.to_hash.compact
      end
      alias_method :save, :set
      def get(key)      db[key]  end
      def [](key)       db[key]  end
      def close()       db.close end
      def size()        db.size  end

      #
      # Load from standard command-line options
      #
      # obvs only works when there's just one store
      #
      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        store = self.new(options[:store_db])
        store
      end
    end
  end
end
