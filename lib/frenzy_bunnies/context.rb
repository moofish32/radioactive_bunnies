require 'logger'
require 'frenzy_bunnies/web'

class FrenzyBunnies::Context
  attr_reader :queue_factory, :opts, :connection
  OPTS = [:host, :heartbeat, :web_host, :web_port, :web_threadfilter, :env, :logger,
          :username, :password, :exchange]

  @@exchange_defaults = {name: 'frenzy_bunnies', type: :direct, durable: false}.freeze
  # Define class level methods that set up a configuration for this context
  # @@config is the class instance variable to store configuration
  # each options can be set by calling class level <option_name> value
  @@config_defaults = { host: 'localhost', heartbeat: 5, web_host: 'localhost', web_port: 11333,
    web_threadfilter: /^pool-.*/, env: 'development', logger: Logger.new(nil),
    exchange: @@exchange_defaults
  }.freeze
  @@config = {}.merge(@@config_defaults)

  OPTS.each do |option|
    define_method option do |value|
      @opts[option] = value
    end

    define_singleton_method option do |value|
      @@config[option] = value
    end
  end

  def self.reset_default_config
    @@config = {}.merge(@@config_defaults)
  end

  def self.configure
    yield @@config if block_given?
    @@config
  end

  def self.config
    @@config
  end

  def self.exchange_defaults
    @@exchange_defaults
  end

  def initialize(opts = {})
    @klasses = []
    @opts = @@config.merge(opts)
    @env = @opts[:env]
    @logger = @opts[:logger]
  end

  def default_exchange
    @opts[:exchange]
  end

  def reset_to_default_config
    @opts = {}.merge(@@config_defaults)
  end

  def run(*klasses)
    start_rabbit_connection!
    klasses.each{|klass| klass.start(self); @klasses << klass}
    start_web_console
  end

  def start_web_console
    return nil if @opts[:disable_web_stats]
    Thread.new do
      FrenzyBunnies::Web.run_with(@klasses, :host => @opts[:web_host], port: @opts[:web_port],
                                  threadfilter: @opts[:web_threadfilter], logger: @logger)
    end
  end

  def start_rabbit_connection!
    params = rabbit_params
    @connection = MarchHare.connect(params)
    @queue_factory = FrenzyBunnies::QueueFactory.new(self)
    @connection.on_shutdown do |conn, cause|
      @logger.error("Disconnected: #{cause}") unless cause.initiated_by_application?
      stop
    end
  end

  def rabbit_params
    params = {:host => @opts[:host], :heartbeat_interval => @opts[:heartbeat]}
    (params[:username], params[:password] = @opts[:username], @opts[:password]) if @opts[:username] && @opts[:password]
    (params[:port] = @opts[:port]) if @opts[:port]
    params
  end

  def stop
    return if @connection.closed?
    @logger.info 'Shutting down workers and closing connection'
    stop_workers
    @connection.close
  end

  def stop_workers
    @logger.info 'Stopping workers'
    @klasses.each{|klass| klass.stop } unless @klasses.empty?
    @logger.info 'Workers have been told to stop'
  end
end

