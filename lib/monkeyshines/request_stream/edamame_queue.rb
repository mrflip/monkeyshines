module Monkeyshines
  module RequestStream
    class EdamameQueue

      def each &block
      end

      def put req
        job = Edamame::Job.from_hash(
          "obj" => req.to_hash
          )
      end
    end
  end
end
