module Monkeyshines
  module Monitor
    class PeriodicMonitor
      attr_accessor :time_interval, :iter_interval
      attr_accessor :last_time, :iter, :started_at

      def initialize options={}
        self.started_at    = Time.now.utc.to_f
        self.last_time     = started_at
        self.iter          = 0
        self.time_interval = options[:time_interval]
        self.iter_interval = options[:iter_interval]
      end

      def enough_iterations?
        iter % iter_interval == 0 if iter_interval
      end

      def enough_time? now
        (now - last_time) > time_interval if time_interval
      end

      def since
        Time.now.utc.to_f - started_at
      end
      def rate
        iter.to_f / since.to_f
      end

      #
      # Ex: log if it has been at least 5 minutes since last announcement:
      #   loop do
      #     # ... stuff ...
      #     Monkeyshines.log_periodically(:stuff, 300){ [radiosity, luminance, bifurcation].join("\t") }
      #   end
      #
      def periodically &block
        self.iter += 1
        now       = Time.now.utc.to_f
        if enough_iterations? || enough_time?(now)
          block.call(iter, (now-last_time))
          self.last_time = now
        end
      end
    end

    class PeriodicLogger < PeriodicMonitor
      def periodically &block
        super do
          result = [ "%7d"%iter, "%7.1f"%rate, (block ? block.call : nil) ].flatten
          Monkeyshines.logger.info result.join("\t")
        end
      end
    end
  end
end
