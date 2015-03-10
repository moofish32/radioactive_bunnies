require 'logger'
require 'frenzy_bunnies/web'
require 'thread_safe'

class FrenzyBunnies::Context
  attr_reader :queue_factory, :opts, :connection, :workers
  OPTS = [:host, :heartbeat, :web_host, :web_port, :web_threadfilter, :env, :logger,
          :username, :password, :exchange, :workers_scope]

  EXCHANGE_DEFAULTS = {name: 'frenzy_bunnies', type: :direct, durable: false}.freeze
  CONFIG_DEFAULTS = { host: 'localhost', heartbeat: 5, web_host: 'localhost', web_port: 11333,
    disable_web_stats: true, web_threadfilter: /^pool-.*/, env: 'development',
    logger: Logger.new(nil), exchange: EXCHANGE_DEFAULTS
  }.freeze

  @@known_workers = ThreadSafe::Hash.new

  OPTS.each do |option|
    define_method option do |value|
      @opts[option] = value
    end
  end

  def self.add_worker(wrk_class)
    @@known_workers[wrk_class.name] = wrk_class
  end

  def initialize(opts = {})
    @opts = CONFIG_DEFAULTS.merge(opts)
    load_workers!
    @env = @opts[:env]
    @logger = @opts[:logger]
  end

  def default_exchange
    @opts[:exchange]
  end

  def reset_to_default_config
    @opts = {}.merge(CONFIG_DEFAULTS)
  end

  def run(*klasses)
    start_rabbit_connection!
    @workers += klasses.flatten unless klasses.empty?
    @workers.each{|klass| klass.start(self)}
    start_web_console
  end

  def stop
    return if @connection.closed?
    @logger.info 'Shutting down workers and closing connection'
    stop_workers
    @connection.close
  end

  def stop_workers
    @logger.info 'Stopping workers'
    @workers.each{|klass| klass.stop } unless @workers.empty?
    @logger.info 'Workers have been told to stop'
  end

  private

  def start_web_console
    return nil if @opts[:disable_web_stats]
    Thread.new do
      FrenzyBunnies::Web.run_with(@workers, :host => @opts[:web_host], port: @opts[:web_port],
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

  def load_workers!
    path_klasses = classes_from_path(@opts[:workers_path])
    @workers = select_workers(path_klasses || [],  @opts[:workers_scope])
  end

  def classes_from_path(path)
    return [] if path.nil?
    klass_names = Dir[File.join(File.expand_path(path), "**/*.rb")].map do |f|
      require f
      File.basename(f).gsub('.rb', '').split('_').map(&:capitalize).join
    end
  end

  def select_workers(klass_names, subdomain)
    return [] if (klass_names.empty? && subdomain.nil?)
    if !!subdomain
      @@known_workers.
        select { |klass_name, cls| klass_name.start_with? @opts[:workers_scope]}.values
    else
      @@known_workers.
        select {|klass_name, cls| klass_names.include? klass_name.split('::').last}.values
    end
  end
end

