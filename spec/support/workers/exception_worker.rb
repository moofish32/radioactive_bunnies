require 'radioactive_bunnies'
class ExceptionWorker
  include RadioactiveBunnies::Worker
  from_queue 'exception.worker'
  def work(metadata, msg)
    raise "I am exceptional"
  end
end
