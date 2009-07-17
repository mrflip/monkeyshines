require 'beanstalk-client'
module Monkeyshines
  module RequestStream
    #
    # Reschedule requests:
    #
    # Estimate rate of items and
    #
    # There's some small session overhead, so you should aim to collect several
    # pages (if you don't mind the slight increase in chance you'll miss items).
    #
    class BeanstalkQueue < Monkeyshines::RequestStream::Base
      DEFAULT_PARAMS = {
        :min_resched_delay => 60*5,     # 5 minutes
        :max_resched_delay => 60*60*24, # one day
        :priority          => 65536,    # default job queue priority
        :time_to_run       => 60*5,     # 5 minutes to complete a session or assume dead
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

      def new_request_from_job job
        args           = job.body.split("\t")
        # request_klass = Wukong.class_from_resource(args.shift)
        session        = request_klass.new(*args[1..-1])
      end

      #
      # Request Stream
      #
      def each &block
        loop do
          job = reserve_job! or next
          session = new_request_from_job(job)
          # Run the scrape session
          yield session
          # reschedule for later
          reschedule job, session
          sleep 1
        end
      end

      # The job queue
      def job_queue
        @job_queue ||= Beanstalk::Pool.new(beanstalk_pool, options[:beanstalk_tube])
      end
      # Close the job queue
      def finish
        @job_queue.close if @job_queue
        @job_queue = nil
      end


      def reserve_job! to=9
        # Reserve a job
        begin job = job_queue.reserve(to)
        rescue Exception => e ; warn e ; sleep 1 ; return ; end
        job
      end

      # ===========================================================================
      #
      # Rescheduling

      #
      # if we can't determine an actual rate, uses max_resched_delay (assumes it
      # is rare)
      #
      def delay_to_next_scrape session
        rate  = session.avg_rate or return max_resched_delay
        delay = items_goal / rate
        delay = delay.clamp(min_resched_delay, max_resched_delay)
        delay.to_i
      end

      def log session, delay=nil, priority=nil
        delay ||= delay_to_next_scrape(session)
        rate_str = session.avg_rate ? "%8.3f" % ((1.0/60)*session.items_per_page/session.avg_rate) : "        "

        ll = "Rescheduling #{"%-25s"%session.query_term}"
        ll << (priority ? " %6d" % priority : "       ")
        ll << " (#{rate_str} min/pg - #{"%6d" % (session.prev_items||0)} items #{"%4d"%(session.new_items||0)} new"
        # ll << ", goal: #{items_goal})"
        ll << " to #{"%7.1f" % (delay/60.0)} min, #{(Time.now + delay).strftime("%Y-%m-%d %H:%M:%S")}"
        Monkeyshines.logger.info ll
      end

      # delegates to #save()
      def <<(session)
        save session
      end
      #
      # Flattens the session and enqueues it with a delay appropriate for the
      # average item rate so far. You can explicitly supply a +priority+ to
      # override the priority set at instantiation.
      def save session, priority=nil, delay=nil
        body       = session.to_flat.join("\t")
        delay    ||= delay_to_next_scrape(session)
        priority ||= options[:priority]
        log session, delay, priority
        job_queue.put body, priority, delay, options[:time_to_run]
      end

      #
      # Re-insert the job at the same priority
      #
      def reschedule job, session
        priority = job.stats['pri']
        job.delete
        self.save session, priority
      end

    end # class
  end
end

# # (1..50).map{ begin j = bs.reserve(1) ; rescue Exception => e ; warn e ; break ; end ; if j then q = j.body.gsub(/\t.*/,"") ; queries[q] ||= j.id ; if (queries[q] != j.id) then j.delete end ; j.release 65536, 45 ; puts q ; q end rescue 'error' }
# pkg=libevent-1.4.11-stable ; sudo true && wget -nc http://monkey.org/~provos/${pkg}.tar.gz     && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local                         && make -j4 && sudo make install )
# pkg=beanstalkd-1.3         ; sudo true && wget -nc http://xph.us/dist/beanstalkd/${pkg}.tar.gz && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local --with-event=/usr/local && make -j4 && sudo make install )

