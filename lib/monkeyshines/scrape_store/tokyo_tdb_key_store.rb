module Monkeyshines
  module ScrapeStore
    #
    # Implementation of KeyStore with a Local TokyoCabinet table database (TDB)
    #
    class TokyoTdbKeyStore < Monkeyshines::ScrapeStore::KeyStore
      
      # pass in the filename or URI of a tokyo cabinet table-style DB
      # set create_db = true if you want to create a missing DB file
      def initialize db_uri, *args
        self.db = TokyoCabinet::TDB.new
        db.open(db_uri, TokyoCabinet::TDB::OWRITER) or raise "#{self.class.to_s}: Can't open TokyoCabinet TDB #{db_uri}"
        super *args
      end
      
      def size()        db.rnum  end
      
    end #class
  end
end
