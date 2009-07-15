require 'json'
module Monkeyshines
  module RawJsonContents
    def parsed_contents
      return @parsed_contents if @parsed_contents
      return nil unless contents
      begin
        @parsed_contents = JSON.load(contents.to_s)
      rescue Exception => e
        warn "JSON not parsing : #{e}" ; return nil
      end
      @parsed_contents
    end

  end
end
