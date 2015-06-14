class RadioactiveBunnies::QueueFactory
  def initialize(context)
    @context = context
    @connection = context.connection
  end

  def build_queue(name, options)
    prefetch = options[:prefetch]
    channel = @connection.create_channel
    channel.prefetch = prefetch
    exchange = create_exchange(channel, options)
    create_and_bind_queue(channel, exchange, name, options)
  end

  private

  def create_and_bind_queue(channel, exchange, name, options)
    routing_key = options[:routing_key] || name
    durable = options[:durable]
    queue = channel.queue(name, :durable => durable )
    queue.bind(exchange, :routing_key => routing_key)
    queue
  end

  def create_exchange(channel, opts)
    config = exchange_config(opts)
    channel.exchange(config.delete(:name), config)
  end

  def exchange_config(opts = {})
    @context.default_exchange.merge(opts[:exchange] || {})
  end
end
