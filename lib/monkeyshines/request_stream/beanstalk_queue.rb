require 'beanstalk-client'
module Monkeyshines
  module RequestStream
    #
    # Persistent job queue for periodic requests.
    #
    # Jobs are reserved, run, and if successful put back with an updated delay parameter.
    #
    # This is useful for mass scraping of timelines (RSS feeds, twitter search
    # results, etc. See http://github.com/mrflip/wuclan for )
    #
    class BeanstalkQueue < Monkeyshines::RequestStream::Base
      DEFAULT_PARAMS = {
        :min_resched_delay => 60*5,     # 5 minutes
        :max_resched_delay => 60*60*24, # one day
        :priority          => 65536,    # default job queue priority
        :time_to_run       => 60*5,     # 5 minutes to complete a job or assume dead
      }
      DEFAULT_BEANSTALK_POOL = ['localhost:11300']
      attr_accessor :beanstalk_pool, :items_goal, :min_resched_delay, :max_resched_delay, :options

      #
      # beanstalk_pool -- specify nil to use the default single-node ['localhost:11300'] pool
      #
      def initialize beanstalk_pool, request_klass, items_goal, options={}
        super request_klass, options
        self.options = options.reverse_merge DEFAULT_PARAMS
        self.beanstalk_pool    = beanstalk_pool || DEFAULT_BEANSTALK_POOL
        self.items_goal        = items_goal
        self.min_resched_delay = self.options.delete :min_resched_delay
        self.max_resched_delay = self.options.delete :max_resched_delay
      end

      #
      # Request Stream
      #
      def each &block
        loop do
          qjob = reserve_job! or next
          scrape_job = scrape_job_from_qjob(qjob)
          # Run the scrape scrape_job
          yield scrape_job
          # reschedule for later
          reschedule qjob, scrape_job
        end
      end

      # ===========================================================================
      #
      # Rescheduling

      #
      # Finish the qjob and re-insert it at the same priority but with the new
      # delay setting.
      #
      def reschedule qjob, scrape_job
        priority = qjob.stats['pri']
        qjob.delete
        self.save scrape_job, priority
      end

      #
      # Flattens the scrape_job and enqueues it with a delay appropriate for the
      # average item rate so far. You can explicitly supply a +priority+ to
      # override the priority set at instantiation.
      #
      # This doesn't delete the job -- use reschedule if you are putting back an
      # existing qjob.
      #
      def save scrape_job, priority=nil, delay=nil
        body       = scrape_job.to_flat.join("\t")
        delay    ||= delay_to_next_scrape(scrape_job)
        priority ||= options[:priority]
        log scrape_job, priority, delay
        job_queue.put body, priority, delay, options[:time_to_run]
      end
      # delegates to #save() -- priority and delay are unchanged.
      def <<(scrape_job) save scrape_job  end

      #
      # if we can't determine an actual rate, uses max_resched_delay (assumes it
      # is rare)
      #
      def delay_to_next_scrape scrape_job
        rate  = scrape_job.avg_rate or return max_resched_delay
        delay = items_goal.to_f / rate
        delay = delay.clamp(min_resched_delay, max_resched_delay)
        delay.to_i
      end

      #
      # A (very prolix) log statement
      #
      def log scrape_job, priority=nil, delay=nil
        delay ||= delay_to_next_scrape(scrape_job)
        rate_str = scrape_job.avg_rate ? "%10.5f/s" % (scrape_job.avg_rate) : " "*12
        ll = "Rescheduling\t#{"%-23s"%scrape_job.query_term}\t"
        ll << "%6d" % priority if priority
        ll << "\t#{rate_str}"
        ll << "\t#{"%7d" % (scrape_job.prev_items||0)}"
        ll << "\t#{"%4d"%(scrape_job.new_items||0)} nu"
        ll << "\tin #{"%8.2f" % delay} s"
        ll << "\t#{(Time.now + delay).strftime("%Y-%m-%d %H:%M:%S")}"
        Log.info ll
      end

      # ===========================================================================
      #
      # Beanstalkd interface
      #

      #
      # De-serialize the scrape job from the queue.
      #
      def scrape_job_from_qjob qjob
        args           = qjob.body.split("\t")
        # request_klass = Wukong.class_from_resource(args.shift)
        scrape_job     = request_klass.new(*args[1..-1])
      end

      # Take the next (highest priority, delay met) job.
      # Set timeout (default is 10s)
      # Returns nil on error or timeout. Interrupt error passes through
      def reserve_job! to=10
        begin  qjob = job_queue.reserve(to)
        rescue Beanstalk::TimedOut => e ; Log.info e.to_s ; sleep 0.4 ; return ;
        rescue StandardError => e       ; Log.warn e.to_s ; sleep 1   ; return ; end
        qjob
      end

      # The beanstalk pool which acts as job queue
      def job_queue
        @job_queue ||= Beanstalk::Pool.new(beanstalk_pool, options[:beanstalk_tube])
      end

      # Close the job queue
      def finish
        @job_queue.close if @job_queue
        @job_queue = nil
      end

      # Stats on job count across the pool
      def job_queue_stats
        job_queue.stats.select{|k,v| k =~ /jobs/}
      end
      # Total jobs in the queue, whether reserved, ready, buried or delayed.
      def job_queue_total_jobs
        stats = job_queue.stats
        [:reserved, :ready, :buried, :delayed].inject(0){|sum,type| sum += stats["current-jobs-#{type}"]}
      end

    end # class
  end
end

# # (1..50).map{ begin j = bs.reserve(1) ; rescue Exception => e ; warn e ; break ; end ; if j then q = j.body.gsub(/\t.*/,"") ; queries[q] ||= j.id ; if (queries[q] != j.id) then j.delete end ; j.release 65536, 45 ; puts q ; q end rescue 'error' }
# pkg=libevent-1.4.11-stable ; sudo true && wget -nc http://monkey.org/~provos/${pkg}.tar.gz     && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local                         && make -j4 && sudo make install )
# pkg=beanstalkd-1.3         ; sudo true && wget -nc http://xph.us/dist/beanstalkd/${pkg}.tar.gz && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local --with-event=/usr/local && make -j4 && sudo make install )

