require 'beanstalk-client'
module Monkeyshines
  #
  # Reschedule requests:
  #
  # Estimate rate of items and
  #
  # There's some small session overhead, so you should aim to collect several
  # pages (if you don't mind the slight increase in chance you'll miss items).
  #
  class RescheduledRequestStream < Monkeyshines::RequestStream
    DEFAULT_PARAMS = {
      :min_resched_delay => 20*1,     # 3x / minute
      :max_resched_delay => 60*60*24, # one day
      :priority          => 65536,    # default job queue priority
      :time_to_run       => 60*5,     # 5 minutes to complete a session or assume dead
      :beanstalk_pool    => ['localhost:11300'],
      # :beanstalk_tube    => nil,
    }
    BEANSTALK_POOL_PARAMS =

    attr_accessor  :items_goal, :min_resched_delay, :max_resched_delay, :options
    def initialize request_klass, items_goal, options={}
      super request_klass, options
      self.options = options.reverse_merge DEFAULT_PARAMS
      self.items_goal        = items_goal
      self.min_resched_delay = self.options.delete :min_resched_delay
      self.max_resched_delay = self.options.delete :max_resched_delay
    end

    def delay_to_next_scrape session
      if session.prev_timespan.size == 0 then return 30 ; end
      delay = items_goal / session.items_rate
      delay = delay.clamp(min_resched_delay, max_resched_delay)
      delay.to_i
    end

    # The job queue
    def job_queue
      @job_queue ||= Beanstalk::Pool.new(options[:beanstalk_pool], options[:beanstalk_tube])
    end
    # Close the job queue
    def finish
      @job_queue.close if @job_queue
    end


    def reserve_job!
      # Reserve a job
      begin job = job_queue.reserve(9)
      rescue Exception => e ; warn e ; sleep 1 ; return ; end
      job
    end

    QUERY_JOBS = { }
    def handle_dupicated job, key
      main_job_id = (QUERY_JOBS[key] ||= job.id)
      if (main_job_id != job.id)
        warn "Already have job #{main_job_id} for #{key}, burying #{job.id}"
        job.bury
        return false
      else
        return true
      end      
    end
    def each &block
      loop do
        job = reserve_job! or next
        # args = job.ybody.values_of(:query_term, :num_items, :min_span, :max_span, :min_timespan, :max_timespan)
        args = job.body.split("\t")
        session = request_klass.new(*args)
        # handle_dupicated(job, session.query_term) or next 
        # Run the scrape session
        yield session
        # reschedule for later
        reschedule job, session
        log(session)
        sleep 1
      end
    end

    def log session
      ll = "Rescheduling #{"%-50s"%session.query_term}"
      ll << " (period: #{"%7.3f" % ((1.0/60)*session.items_per_page/session.items_rate)} min/pg - #{session.num_items} items in #{session.prev_timespan.size}"
      ll << ", goal: #{items_goal})"
      next_time     = Time.now + delay_to_next_scrape(session)
      delay_minutes = delay_to_next_scrape(session).to_f / 60.0
      ll << " to #{"%7.3f" % delay_minutes} min, #{next_time.strftime("%Y-%m-%d %H:%M:%S")}"
      Monkeyshines.logger.info ll
    end

    def reschedule job, session
      # delay = delay_to_next_scrape(session)
      # session.to_hash.each{|k,v| job[k] = v }
      # job.release(options[:priority], delay)
      job.delete
      self << session
    end
    def <<(session)
      body  = session.to_flat.join("\t")
      delay = delay_to_next_scrape(session)
      job_queue.put body, options[:priority], delay, options[:time_to_run]      
    end
    # delegates to <<()
    def save session
      self << session
    end

  end

end

# # (1..50).map{ begin j = bs.reserve(1) ; rescue Exception => e ; warn e ; break ; end ; if j then q = j.body.gsub(/\t.*/,"") ; queries[q] ||= j.id ; if (queries[q] != j.id) then j.delete end ; j.release 65536, 45 ; puts q ; q end rescue 'error' }

# pkg=libevent-1.4.11-stable ; sudo true && wget -nc http://monkey.org/~provos/${pkg}.tar.gz     && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local                         && make -j4 && sudo make install )
# pkg=beanstalkd-1.3         ; sudo true && wget -nc http://xph.us/dist/beanstalkd/${pkg}.tar.gz && tar xvzf ${pkg}.tar.gz && ( cd ${pkg} && ./configure --prefix=/usr/local --with-event=/usr/local && make -j4 && sudo make install )
