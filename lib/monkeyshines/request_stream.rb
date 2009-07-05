module Monkeyshines
  class RequestStream
    attr_accessor :request_klass
    def initialize request_klass
      self.request_klass = request_klass
    end
  end

  class FlatFileRequestStream < RequestStream
    attr_accessor :filename
    def initialize filename, *args
      self.filename = filename
      super *args
    end

    def each &block
      File.open filename do |f|
        f.each do |line|
          req = request_klass.new( *line.chomp.split("\t") )
          yield req
        end
      end
    end
  end
end
