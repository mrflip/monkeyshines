require 'edamame'
require 'digest'
module Monkeyshines
  module RequestStream



    class EdamameQueue < Edamame::Broker
      def initialize _options
        tube = Monkeyshines::CONFIG[:handle].to_s.gsub(/_/, '')
        super _options.deep_merge( :tube => tube )
      end

      def each &block
        work(10) do |job|
          yield job.obj['type'], job.obj
        end
        p [queue, queue.beanstalk_stats]
      end

      def req_to_job req, job_options={}
        obj_hash = req.to_hash.merge(
          'type' => req.class.to_s,
          'key'  => [req.class.to_s, req.key].join('-')
          )
        Edamame::Job.from_hash(job_options.merge("obj" => obj_hash,
            'priority' => (66000 + 1000*req.req_generation),
            'tube' => tube ))
      end

      def put job, *args
        job_options = args.extract_options!
        job = req_to_job(job, job_options) unless job.is_a?(Beanstalk::Job) || job.is_a?(Edamame::Job)
        # p [self.class, job.key, job.obj,job.scheduling, job_options, args]
        super job, *args
      end
    end
  end
end
