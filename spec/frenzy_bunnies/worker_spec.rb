require 'spec_helper'
require 'frenzy_bunnies'

class DummyWorker
  include FrenzyBunnies::Worker
  from_queue 'dummy.worker'
  def work(metadata, msg)
    true
  end
end

class TimeoutWorker
  include FrenzyBunnies::Worker
  from_queue 'timeout.worker', timeout_job_after: 1
  def work(metadata, msg)
    while(true) do
    end
  end
end

class ExceptionWorker
  include FrenzyBunnies::Worker
  from_queue 'exception.worker'
  def work(metadata, msg)
    raise "I am exceptional"
  end
end

class FailedWorker
  include FrenzyBunnies::Worker
  from_queue 'failed.worker'
  def work(metadata, msg)
    false
  end
end

class CustomWorker
  include FrenzyBunnies::Worker
  from_queue 'custom.worker', :prefetch => 20, :durable => true, :timeout_job_after => 13,
    :threads => 25, append_env: true
  def work(metadata, msg)
  end
end


describe FrenzyBunnies::Worker do
  before(:all) do
    @conn = MarchHare.connect
    @ch = @conn.create_channel
    FrenzyBunnies::Context.reset_default_config
    @ctx = FrenzyBunnies::Context.new(logger: Logger.new(STDOUT))
    @ctx.run TimeoutWorker, ExceptionWorker, FailedWorker, DummyWorker, CustomWorker
    ['failed.worker', 'timeout.worker', 'dummy.worker', 'exception.worker'].each do |r_key|
      @ch.default_exchange.publish("hello world", routing_key: r_key)
    end
    sleep 2
  end

  after(:all) do
    @conn.close
    @ctx.stop
  end

  it "should start with a clean slate" do
    # check stats, default configuration
    expect(CustomWorker.jobs_stats[:failed]).to eql 0
    expect(CustomWorker.jobs_stats[:passed]).to eql 0
    expect(CustomWorker.queue_opts).
      to match({:prefetch => 20, :durable => true, :timeout_job_after => 13, :threads => 25,
                append_env: true})
  end

  it "should respond to configuration tweaks" do
    # check that all params are changed
    q = CustomWorker.queue_opts
    q[:timeout_job_after] = 1
    expect(CustomWorker.queue_opts).to include(timeout_job_after: 1)
    q[:timeout_job_after] = 13
  end

  it 'includes context env if append_env: true is provided' do
    expect(CustomWorker.queue_name).to eql 'custom.worker_development'
  end

  it "should stop when asked to" do
    CustomWorker.stop
    expect(CustomWorker.stopped?).to be_truthy
  end

  it "should acknowledge a unit of work when worker succeeds" do
    expect(DummyWorker.jobs_stats[:passed]).to eql 1
    expect(DummyWorker.jobs_stats[:failed]).to eql 0
  end

  it "does not acknowledge failed work and tracks failures" do
    expect(FailedWorker.jobs_stats[:failed]).to eql 1
    expect(FailedWorker.jobs_stats[:passed]).to eql 0
  end

  it "should reject a unit of work when worker times out" do
    expect(TimeoutWorker.jobs_stats[:failed]).to eql 1
    expect(TimeoutWorker.jobs_stats[:passed]).to eql 0
  end

  it "should reject a unit of work when worker fails exceptionally" do
    expect(ExceptionWorker.jobs_stats[:failed]).to eql 1
    expect(ExceptionWorker.jobs_stats[:passed]).to eql 0
  end
end
