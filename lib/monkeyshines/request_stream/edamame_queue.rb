require 'edamame'
require 'digest'
module Monkeyshines
  module RequestStream

    class EdamameQueueJob < Edamame::Job
      def queue
      end
    end

    
    class EdamameQueue < Edamame::PersistentQueue
      def initialize _options
        tube = Monkeyshines::CONFIG[:handle].to_s.gsub(/_/, '')
        super _options.deep_merge( :tube => tube )
      end
      
      def each &block
        super do |job|
          yield [job.obj['type'], job.obj]
        end
      end

      def req_to_job req
        obj_hash = req.to_hash.merge(
          'type' => req.class.to_s,
          'key'  => req.key
          )
        Edamame::Job.from_hash( "obj" => obj_hash )
      end
      
      def put job
        job = req_to_job(job) unless job.is_a?(Beanstalk::Job) || job.is_a?(Edamame::Job)
        super job
      end
    end
  end
end
