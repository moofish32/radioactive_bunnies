require 'radioactive_bunnies'
class FailedWorker
  include RadioactiveBunnies::Worker
  from_queue 'failed.worker'
  def work(metadata, msg)
    false
  end
end
