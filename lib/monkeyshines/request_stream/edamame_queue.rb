module Monkeyshines
  module RequestStream
    #
    # Watch for jobs in an Edamame priority queue
    # (http://mrflip.github.com/edamame)
    #
    class EdamameQueue < Edamame::Broker
      # How long to wait for tasks
      cattr_accessor :queue_request_timeout
      self.queue_request_timeout = 5 * 60 # seconds
      # priority for search jobs if not otherwise given
      QUEUE_PRIORITY = 65536

      def initialize _options
        tube = Monkeyshines::CONFIG[:handle].to_s.gsub(/_/, '-')
        super _options.deep_merge( :tube => tube )
      end

      def each klass, &block
        work(queue_request_timeout, klass) do |job|
          job.each_request(&block)
        end
        Log.info [queue, queue.beanstalk_stats]
      end

      # def each &block
      #   work(queue_request_timeout) do |job|
      #     yield job.obj['type'], job.obj
      #   end
      #   Log.info [queue, queue.beanstalk_stats]
      # end

      def req_to_job req, job_options={}
        obj_hash = req.to_hash.merge(
          'type' => req.class.to_s,
          'key'  => [req.class.to_s, req.key].join('-')  )
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
