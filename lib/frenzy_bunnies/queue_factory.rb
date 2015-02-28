class FrenzyBunnies::QueueFactory
  def initialize(context)
    @context = context
    @connection = context.connection
  end

  def build_queue(name, options)
    exchange_params = exchange_config(options)
    routing_key = options[:routing_key] || name
    durable = options[:durable]
    prefetch = options[:prefetch]

    channel = @connection.create_channel
    channel.prefetch = prefetch
    puts exchange_params
    exchange = channel.exchange(exchange_params[:name],
                                type: exchange_params[:type], durable: exchange_params[:durable])

    queue = channel.queue(name, :durable => durable)
    queue.bind(exchange, :routing_key => routing_key)
    queue
  end

  def exchange_config(opts = {})
    @context.default_exchange.merge(opts[:exchange] || {})
  end
end
