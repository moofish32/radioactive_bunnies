require 'frenzy_bunnies'
class ExceptionWorker
  include FrenzyBunnies::Worker
  from_queue 'exception.worker'
  def work(metadata, msg)
    raise "I am exceptional"
  end
end
