require 'radioactive_bunnies'
class DummyWorker
  include RadioactiveBunnies::Worker
  from_queue 'dummy.worker'
  def work(metadata, msg)
    true
  end
end

