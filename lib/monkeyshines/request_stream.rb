module Monkeyshines
  class RequestStream
    attr_accessor :request_klass
    def initialize request_klass, options={}
      self.request_klass = request_klass
    end

    def self.new_from_command_line cmdline_opts, default_opts={}
      options = default_opts.merge(cmdline_opts)
      Trollop::die :from, "is required: location of scrape request stream" if options[:from].blank?
      request_stream = Monkeyshines::FlatFileRequestStream.new(options[:from], options[:request_klass])
      request_stream.skip! options[:skip] if options[:skip].to_i > 0
      request_stream
    end

  end

  class FlatFileRequestStream < RequestStream
    attr_accessor :filename
    def initialize filename, *args
      self.filename = filename
      super *args
    end

    def file
      @file ||= File.open(filename)
    end

    def skip! n_lines
      Monkeyshines.logger.info "Skipping #{n_lines} in #{self.class}:#{filename}"
      n_lines.times do
        file.readline
      end
    end

    def each &block
      file.each do |line|
        req = request_klass.new( *line.chomp.split("\t") )
        yield req
      end
    end
  end
end
