require 'frenzy_bunnies'
class FailedWorker
  include FrenzyBunnies::Worker
  from_queue 'failed.worker'
  def work(metadata, msg)
    false
  end
end
