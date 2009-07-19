require 'tokyotyrant'
module Monkeyshines
  module ScrapeStore

    #
    # Implementation of KeyStore with a Local TokyoCabinet hash database (HDB)
    #
    class TyrantHdbKeyStore < Monkeyshines::ScrapeStore::KeyStore
      attr_accessor :db_host, :db_port

      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri=nil, *args
        db_uri ||= ':1978'
        self.db_host, self.db_port = db_uri.split(':')
        self.db = TokyoTyrant::RDB.new
        db.open(db_host, db_port) or raise("Can't open DB #{db_uri}. Pass in host:port, default is ':1978' #{db.ecode}: #{db.errmsg(db.ecode)}")
        super *args
      end

      # Save the value into the database without waiting for a response.
      def set_nr(key, val)
        db.putnr key, val if val
      end

      def size()        db.rnum  end
      def include? *args
        db.has_key? *args
      end
      
      # require 'memcache'
      # def initialize db_uri=nil, *args
      #   # db_uri ||= ':1978'
      #   # self.db_host, self.db_port = db_uri.split(':')
      #   self.db = MemCache.new(db_uri, :no_reply => true)
      #   if !self.db then raise("Can't open DB #{db_uri}. Pass in host:port, default is ':1978' #{db.ecode}: #{db.errmsg(db.ecode)}") end
      #   super *args
      # end
      #
      # def size
      #   db.stats
      # end

    end #class
  end
end

