STANDARD_OPTS = {
  :monitor_group   => nil,
  :user            => nil,
  :restart_notify  => nil, # need to set up the God.contacts in the global config.
  :flapping_notify => nil, # need to set up the God.contacts in the global config.
}

#
#
#
def god_are_one_of_us handle, opts
  God.watch do |w|
    w.name             = handle
    w.group            = opts[:monitor_group] if opts[:monitor_group]
    w.interval         =  1.minute
    w.start_grace      = 20.seconds
    w.restart_grace    = 20.seconds
    w.start            = opts[:start_command]
    # w.stop             = ""
    # w.restart          = ""
    w.uid              = opts[:user] if opts[:user]
    w.behavior(:clean_pid_file)

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval     = 1.minute
        c.running      = false
      end
    end

    w.restart_if do |restart|
      restart.condition(:memory_usage) do |c|
        c.above      = opts[:max_mem_usage] || 150.megabytes
        c.times      = [3, 5] # 3 out of 5 intervals
      end
      restart.condition(:cpu_usage) do |c|
        c.above      = opts[:max_cpu_usage] || 50.percent
        c.times      = 5
      end
      c.notify       = opts[:restart_notify] if opts[:restart_notify]
    end

    # lifecycle
    w.lifecycle do |on|
      on.condition(:flapping) do |c|
        c.to_state     = [:start, :restart]
        c.times        = 10
        c.within       = 15.minute
        c.transition   = :unmonitored
        c.retry_in     = 60.minutes
        c.retry_times  = 5
        c.retry_within = 12.hours
        c.notify       = opts[:flapping_notify] if opts[:flapping_notify]
      end
    end
  end
end
