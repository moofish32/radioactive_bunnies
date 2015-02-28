require 'atomic'

module FrenzyBunnies::Worker
  def ack!
    true
  end

  def work
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def from_queue(q, opts={})
      @queue_name = q
      @queue_opts = opts
    end

    def start(context)
      @jobs_stats = { :failed => Atomic.new(0), :passed => Atomic.new(0) }
      @working_since = Time.now

      @logger = context.logger

      queue_name = "#{@queue_name}_#{context.env}"

      @queue_opts[:prefetch] ||= 10
      @queue_opts[:durable] ||= false
      @queue_opts[:timeout_job_after] ||=5

      if @queue_opts[:threads]
        @thread_pool = MarchHare::ThreadPools.fixed_of_size(@queue_opts[:threads])
      else
        @thread_pool = MarchHare::ThreadPools.dynamically_growing
      end

      q = context.queue_factory.build_queue(queue_name, @queue_opts)

      say "#{@queue_opts[:threads] ? "#{@queue_opts[:threads]} threads " : ''}with #{@queue_opts[:prefetch]} prefetch on <#{queue_name}>."

      q.subscribe(:ack => true, :blocking => false, :executor => @thread_pool) do |metadata, payload|
        wkr = new
        begin
          Timeout::timeout(@queue_opts[:timeout_job_after]) do
            if(wkr.work(payload, metadata))
              metadata.ack
              incr! :passed
            else
              metadata.reject
              incr! :failed
              error "REJECTED", payload
            end
          end
        rescue Timeout::Error
          metadata.reject
          incr! :failed
          error "TIMEOUT #{@queue_opts[:timeout_job_after]}s", payload
        rescue
          metadata.reject
          incr! :failed
          error "ERROR #{$!}", payload
        end
      end

      say "workers up."
    end

    def stop
      say "stopping"
      @thread_pool.shutdown_now say "pool shutdown"
      # @s.cancel  #for some reason when the channel socket is broken, this is holding the process up and we're zombie.
      say "stopped"
    end

    def queue_opts
      @queue_opts
    end

    def jobs_stats
      Hash[ @jobs_stats.map{ |k,v| [k, v.value] } ].merge({ :since => @working_since.to_i })
    end
  private
    def say(text)
      @logger.info "[#{self.name}] #{text}"
    end

    def error(text, msg)
      @logger.error "[#{self.name}] #{text} <#{msg}>"
    end

    def incr!(what)
      @jobs_stats[what].update { |v| v + 1 }
    end
  end
end

