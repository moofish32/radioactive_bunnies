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
    exchange = create_exchange(channel, q_opts)
    create_and_bind_queue(channel, exchange, name, q_opts)
  end

  private

  def create_and_bind_queue(channel, exchange, name, options)
    routing_key = options[:routing_key] || name
    durable = options[:durable]
    queue = channel.queue(name, :durable => durable )
    queue.bind(exchange, :routing_key => routing_key)
    queue
  end

  def create_exchange(channel, q_opts)
    config = exchange_config(q_opts)
    channel.exchange(config.delete(:name), config)
  end

  def exchange_config(q_opts = {})
    @context.default_exchange.merge(q_opts[:exchange] || {})
  end
end
