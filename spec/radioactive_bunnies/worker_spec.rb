require 'spec_helper'
require 'radioactive_bunnies'
require 'support/workers/timeout_worker'
require 'support/workers/exception_worker'
require 'support/workers/dummy_worker'
require 'support/workers/failed_worker'

class CustomWorker
  include RadioactiveBunnies::Worker
  from_queue 'custom.worker', :prefetch => 20, :durable => true, :timeout_job_after => 13,
    :threads => 25, append_env: true
  def work(metadata, msg)
  end
end


describe RadioactiveBunnies::Worker do
  before(:all) do
    @conn = MarchHare.connect
    @ch = @conn.create_channel
    @ctx = RadioactiveBunnies::Context.new(logger: Logger.new(STDOUT))
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
      to include({:prefetch => 20, :durable => true, :timeout_job_after => 13, :threads => 25,
                append_env: true})
  end

  it "should respond to configuration tweaks" do
    # check that all params are changed
    q = CustomWorker.queue_opts
    q[:timeout_job_after] = 1
    expect(CustomWorker.queue_opts).to include(timeout_job_after: 1)
    q[:timeout_job_after] = 13
  end

  it 'informs the RadioactiveBunnies::Context that a worker has been defined' do
    class HardlyWorks; end
    expect(RadioactiveBunnies::Context).to receive(:add_worker).with(HardlyWorks)
    class HardlyWorks; include RadioactiveBunnies::Worker; end
  end

  it 'includes context env if append_env: true is provided' do
    expect(CustomWorker.queue_name).to eql 'custom.worker_development'
  end

  it "should stop when asked to" do
    CustomWorker.stop
    expect(CustomWorker.stopped?).to be_truthy
  end

  it "should acknowledge a unit of work when worker succeeds" do
    expect(DummyWorker.jobs_stats[:failed]).to eql 0
    expect(DummyWorker.jobs_stats[:passed]).to eql 1
  end

  it "does not acknowledge failed work and tracks failures" do
    expect(FailedWorker.jobs_stats[:failed]).to eql 1
    expect(FailedWorker.jobs_stats[:passed]).to eql 0
  end

  it "should reject a unit of work when worker times out" do
    expect(TimeoutWorker.jobs_stats[:failed]).to be > 0
    expect(TimeoutWorker.jobs_stats[:passed]).to eql 0
  end

  it "should reject a unit of work when worker fails exceptionally" do
    expect(ExceptionWorker.jobs_stats[:failed]).to eql 1
    expect(ExceptionWorker.jobs_stats[:passed]).to eql 0
  end
end
