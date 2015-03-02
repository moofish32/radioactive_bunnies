require 'logger'
require 'frenzy_bunnies/web'

class FrenzyBunnies::Context
  attr_reader :queue_factory, :logger, :env, :opts, :connection
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
    define_singleton_method option do |value|
      @@config[option] = value
    end
  end
  class << self
    def reset_default_config
      @@config = {}.merge(@@config_defaults)
    end

    def configure
      yield @@config if block_given?
      @@config
    end
    alias_method :config, :configure

    def exchange_defaults
      @@exchange_defaults
    end
  end

  def initialize(opts = {})
    @klasses = []
    @opts = @@config.merge(opts)
    @env = @opts[:env]
    @logger = @opts[:logger]

    params = {:host => @opts[:host], :heartbeat_interval => @opts[:heartbeat]}
    (params[:username], params[:password] = @opts[:username], @opts[:password]) if @opts[:username] && @opts[:password]
    (params[:port] = @opts[:port]) if @opts[:port]

    @connection = MarchHare.connect(params)
    @connection.on_shutdown do |conn, cause|
      @logger.error("Disconnected: #{cause}") unless cause.initiated_by_application?
      stop
    end

    @queue_factory = FrenzyBunnies::QueueFactory.new(self)
  end

  def default_exchange
    @opts[:exchange]
  end

  def reset_default_config
    puts @@config_defaults
    @opts = {}.merge(@@config_defaults)

  end
  def run(*klasses)
    klasses.each{|klass| klass.start(self); @klasses << klass}
    return nil if @opts[:disable_web_stats]
    Thread.new do
      FrenzyBunnies::Web.run_with(@klasses, :host => @opts[:web_host], :port => @opts[:web_port], :threadfilter => @opts[:web_threadfilter], :logger => @logger)
    end
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

