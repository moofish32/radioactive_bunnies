require 'atomic'
require 'radioactive_bunnies/context'

module RadioactiveBunnies::Worker

  def ack!
    true
  end

  def work
  end

  def self.included(base)
    base.extend ClassMethods
    RadioactiveBunnies::Context.add_worker(base)
  end

  module ClassMethods

    def from_queue(q_name, opts={})
      @queue_name = q_name
      @queue_opts = opts
    end

    def start(context)
      @jobs_stats = { :failed => Atomic.new(0), :passed => Atomic.new(0) }
      @working_since = Time.now

      @logger = context.logger

      @queue_opts[:prefetch] ||= 10
      @queue_opts[:durable] ||= false
      @queue_opts[:timeout_job_after] ||=5

      if @queue_opts[:threads]
        @thread_pool = MarchHare::ThreadPools.fixed_of_size(@queue_opts[:threads])
      else
        @thread_pool = MarchHare::ThreadPools.dynamically_growing
      end

      @queue_name = "#{@queue_name}_#{context.opts[:env]}" if @queue_opts[:append_env]
      q = context.queue_factory.build_queue(@queue_name, @queue_opts)

      say "#{@queue_opts[:threads] ? "#{@queue_opts[:threads]} threads " : ''}with #{@queue_opts[:prefetch]} prefetch on <#{@queue_name}>."

      q.subscribe(:ack => true, :blocking => false, :executor => @thread_pool) do |metadata, payload|
        wkr = new
        begin
          Timeout::timeout(@queue_opts[:timeout_job_after]) do
            if(wkr.work(metadata, payload))
              metadata.ack
              incr! :passed
            else
              metadata.reject
              incr! :failed
              error "REJECTED", metadata
            end
          end
        rescue Timeout::Error
          metadata.reject
          incr! :failed
          error "TIMEOUT #{@queue_opts[:timeout_job_after]}s", metadata
        rescue
          metadata.reject
          incr! :failed
          error "ERROR #{$!}", metadata
        end
      end

      say "workers up."
    end

    def stop
      return if stopped?
      say "stopping"
      @thread_pool.shutdown_now
      say "stopped"
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def queue_opts
      @queue_opts
    end

    def queue_name
      @queue_name
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

