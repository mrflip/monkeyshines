# From http://god.rubyforge.org/
#
# run with:  god -c /path/to/gravatar.god
#
# This is the actual config file used to keep the mongrels of
# gravatar.com running.

# God.pid_file_directory = '/home/tom/pids'
BEANSTALKD_ROOT = '/usr/local/'
BEANSTALKD_DEFAULTS = { 
  :listen_on         => '0.0.0.0',
  :port              => 11300,
  :max_cpu_usage     => 50.percent,
  :max_mem_usage     => 150.megabytes,
}

def beanstalkd_start_command opts
  [
    "#{BEANSTALKD_ROOT}/bin/beanstalkd",
    "-l #{opts[:listen_on]}",
    "-p #{opts[:port]}",
    "-z #{opts[:max_job_size]}"   if opts[:max_job_size],
    "-u #{opts[:user]}"           if opts[:user],
    ].flatten.compact.join(" ")
end

def beanstalkd_stop_command opts
  'killall beanstalkd'
end

#
#
#
def are_you_there_god_its_me_beanstalk handle, opts
  opts                   = opts.reverse_merge(BEANSTALKD_DEFAULTS)
  opts[:start_command]   = beanstalkd_start_command(opts)
  opts[:stop_command]    = beanstalkd_stop_command(opts)
  opts[:restart_command] = [beanstalkd_stop_command, "sleep 2", beanstalkd_start_command].join(" && ")
  god_are_one_of_us handle, opts
end
