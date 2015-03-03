require 'frenzy_bunnies'
class DummyWorker
  include FrenzyBunnies::Worker
  from_queue 'dummy.worker'
  def work(metadata, msg)
    true
  end
end

