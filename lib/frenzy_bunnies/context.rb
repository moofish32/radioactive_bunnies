require 'logger'
require 'frenzy_bunnies/web'

class FrenzyBunnies::Context
  attr_reader :queue_factory, :logger, :env, :opts, :connection
  OPTS = [:host, :heartbeat, :web_host, :web_port, :web_threadfilter, :env, :logger,
          :username, :password, :exchange]

  @@exchange_defaults = {name: 'frenzy_bunnies', type: :direct, durable: false}
  # Define class level methods that set up a configuration for this context
  # @@config is the class instance variable to store configuration
  # each options can be set by calling class level <option_name> value
  @@config = {}
  OPTS.each do |option|
    define_singleton_method option do |value|
      @@config[option] = value
    end
  end
  class << self
    def clear_config
      @@config = {}
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
    @opts[:host]     ||= 'localhost'
    @opts[:heartbeat] ||= 5
    @opts[:web_host] ||= 'localhost'
    @opts[:web_port] ||= 11333
    @opts[:web_threadfilter] ||= /^pool-.*/
    @opts[:env] ||= 'development' unless @opts.key? :env
    @opts[:exchange] = @@exchange_defaults.merge(opts[:exchange] || {})

    @env = @opts[:env]
    @logger = @opts[:logger] || Logger.new(STDOUT)
    params = {:host => @opts[:host], :heartbeat_interval => @opts[:heartbeat]}
    (params[:username], params[:password] = @opts[:username], @opts[:password]) if @opts[:username] && @opts[:password]
    (params[:port] = @opts[:port]) if @opts[:port]
    @connection = MarchHare.connect(params)
    @connection.add_shutdown_listener(lambda { |cause|  stop(cause)})

    @queue_factory = FrenzyBunnies::QueueFactory.new(self)
  end

  def default_exchange
    @opts[:exchange]
  end

  def run(*klasses)
    klasses.each{|klass| klass.start(self); @klasses << klass}
    return nil if @opts[:disable_web_stats]
    Thread.new do
      FrenzyBunnies::Web.run_with(@klasses, :host => @opts[:web_host], :port => @opts[:web_port], :threadfilter => @opts[:web_threadfilter], :logger => @logger)
    end
  end

  def stop(cause = nil)
    @logger.info "Shutting down workers and closing connection" unless @stop_requested
    @stop_requested = true if cause.nil?
    @logger.error("Disconnected: #{cause}") unless @stop_requested
    @klasses.each{|klass| klass.stop } unless @klasses.empty?
    @connection.close unless @connection.closed?
  end
end

