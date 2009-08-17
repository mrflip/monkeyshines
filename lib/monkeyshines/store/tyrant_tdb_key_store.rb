require 'tokyotyrant'
module Monkeyshines
  module Store
    #
    # Implementation of KeyStore with a Local TokyoCabinet hash database (RDB)
    #
    class TyrantRdbKeyStore < Monkeyshines::Store::KeyStore
      attr_accessor :db_host, :db_port

      # pass in the host:port uri of the key store.
      def initialize options
        self.db_host, self.db_port = options[:uri].to_s.split(':')
        super options
      end

      def db
        return @db if @db
        @db ||= TokyoTyrant::RDBTBL.new
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

    end #class
  end
end

