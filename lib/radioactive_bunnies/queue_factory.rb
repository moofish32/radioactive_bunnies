class RadioactiveBunnies::QueueFactory

  QUEUE_DEFAULTS = {
    prefetch: 10,
    durable: false,
    timeout_job_after: 5
  }

  def initialize(context)
    @context = context
    @connection = context.connection
  end

  def build_queue(name, options = {})
    q_opts = QUEUE_DEFAULTS.merge(options)
    channel = @connection.create_channel
    channel.prefetch = q_opts[:prefetch]
    exchange = exchange_params(channel, q_opts)
    create_and_bind_queue(channel, exchange, name, q_opts)
  end

  private

  def create_and_bind_queue(channel, exchange, name, q_opts)
    routing_key = q_opts[:routing_key] || name
    queue = channel.queue(name, queue_params(q_opts))
    queue.bind(exchange, :routing_key => routing_key)
    queue
  end

  def queue_params(q_opts)
    opts = {durable: q_opts[:durable]}
    opts.merge(RadioactiveBunnies::DeadletterWorker.deadletter_queue_config(q_opts))
  end

  def exchange_params(channel, q_opts)
    config = exchange_config(q_opts)
    channel.exchange(config.delete(:name), config)
  end

  def exchange_config(q_opts = {})
    @context.default_exchange.merge(q_opts[:exchange] || {})
  end
end
