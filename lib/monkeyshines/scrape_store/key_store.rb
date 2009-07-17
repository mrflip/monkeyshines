#require "rufus/tokyo"
#require "rufus/tokyo/cabinet/hash"
require 'tokyotyrant'
module Monkeyshines
  module ScrapeStore
    class KeyStore < Monkeyshines::ScrapeStore::Base
      # The actual backing store; should respond to #set and #get methods
      attr_accessor :db

      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri, create_db=false, *args
        super *args
        self.db = TokyoTyrant::RDBTBL.new
        db.open(db_uri||"", 1978) or raise("Can't open DB: #{db.ecode}: #{db.errmsg(db.ecode)}")
      end

      # Delegate to store
      def set(key, val)
        return unless val
        db.put key, val.to_hash
      end
      alias_method :save, :set
      def get(key)      db[key]  end
      def [](key)       db[key]  end
      def close()       db.close end
      def size()        db.size  end

      def each &block
        iter = db.iterinit
        loop do
          key = db.iternext or break
          yield db[key]
        end
      end

      #
      # Load standard command-line options
      #
      def self.new_from_command_line cmdline_opts, default_opts={}
        options = default_opts.merge(cmdline_opts)
        store = self.new(options[:store_db], options[:create_db])
        Trollop::die :store_db, "isn't a tokyo cabinet DB I could load" unless store.db
        store
      end
    end
  end
end
