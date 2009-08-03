require 'tokyotyrant'
module Monkeyshines
  module Store

    #
    # Implementation of KeyStore with a Local TokyoCabinet hash database (RDB)
    #
    class TyrantRdbKeyStore < Monkeyshines::Store::KeyStore
      attr_accessor :db_host, :db_port

      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri, *args
        self.db_host, self.db_port = db_uri.split(':')
        super *args
      end

      def db
        return @db if @db
        @db ||= TokyoTyrant::RDB.new
        @db.open(db_host, db_port) or raise("Can't open DB #{db_host}:#{db_port}. Pass in host:port' #{@db.ecode}: #{@db.errmsg(@db.ecode)}")
        @db
      end

      def close
        @db.close if @db
        @db = nil
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

