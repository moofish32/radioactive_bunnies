require 'spec_helper'
require 'radioactive_bunnies'
require 'support/workers/timeout_worker'

class DeadletterDefaultWorker
  include RadioactiveBunnies::Worker
  from_queue 'deadletter.default',
    prefetch: 20, durable: false, timeout_job_after: 5, threads: 1, append_env: true,
    exchange: {type: :fanout, name: 'deadletter.exchange'}
  def work(metadata, msg)
    true
  end
end

class DeadletterProducer
  include RadioactiveBunnies::Worker
  from_queue 'deadletter.producer',
    prefetch: 20, timeout_job_after: 1, threads: 2,
    deadletter_workers: ['DeadletterDefaultWorker']
  def work(metadata, msg)
    sleep 10
  end
end

class DeadletterProducerNonArray
  include RadioactiveBunnies::Worker
  from_queue 'deadletter.producer.nonarray',
    prefetch: 20, timeout_job_after: 1, threads: 2,
    deadletter_workers: 'DeadletterDefaultWorker'
  def work(metadata, msg)
    sleep 10
  end
end

describe RadioactiveBunnies::Worker do

  before(:all) do
    @conn = MarchHare.connect
    @ch = @conn.create_channel
    @ctx = RadioactiveBunnies::Context.new(logger: Logger.new(STDOUT))
    @ctx.run DeadletterProducer, DeadletterDefaultWorker, DeadletterProducerNonArray
    ['deadletter.producer', 'deadletter.producer.nonarray'].each do |r_key|
      @ch.default_exchange.publish("hello world", routing_key: r_key)
    end
    sleep 2
  end

  after(:all) do
    @conn.close
    @ctx.stop
  end
  context 'when a worker has at least one deadletter class' do

    it 'notifies the deadletter worker that it will produce deadletters' do
      expect(DeadletterDefaultWorker.deadletter_producers).to include(DeadletterProducer.name)
    end
    it 'notifies the deadletter worker when a single deadletter work is identified' do
      expect(DeadletterDefaultWorker.deadletter_producers).to include(DeadletterProducerNonArray.name)
    end
  end

  context 'when a worker with deadletter enabled timesout' do
    it 'sends the deadletter to the correct deadletter worker' do
      expect(DeadletterProducerNonArray.jobs_stats[:failed]).to eql 1
      expect(DeadletterProducerNonArray.jobs_stats[:passed]).to eql 0
      expect(DeadletterDefaultWorker.jobs_stats[:passed]).to eql 2
    end
  end
end
