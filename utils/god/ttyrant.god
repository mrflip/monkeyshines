# From http://god.rubyforge.org/
#
# run with:  god -c /path/to/gravatar.god
#
# This is the actual config file used to keep the mongrels of
# gravatar.com running.

# God.pid_file_directory = '/home/tom/pids'
BEANSTALKD_ROOT = '/usr/local/'

#
#
#

def are_you_there_god_its_me_beanstalk handle, opts
  opts = opts.reverse_merge(
    :listen_on    => '0.0.0.0',
    :port         => 11300,
    :user         => '',
    :max_job_size => '65535',
    )
  God.watch do |w|
    w.name          = handle
    w.interval      =  1.minute
    w.start_grace   = 10.seconds
    w.restart_grace = 10.seconds
    w.start         = "#{BEANSTALKD_ROOT}/bin/beanstalkd -l #{opts[:listen_on]} -p #{opts[:port]} -z #{opts[:max_job_size]}"
    # w.stop          = ""
    # w.restart       = ""
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 1.minute
        c.running  = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above = 150.megabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end
      restart.condition(:cpu_usage) do |c|
        c.above = 50.percent
        c.times = 5
      end
    end

    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state = [:start, :restart]
        c.times = 5
        c.within = 5.minute
        c.transition = :unmonitored
        c.retry_in = 10.minutes
        c.retry_times = 5
        c.retry_within = 2.hours
      end
    end
  end
end
