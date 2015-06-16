require 'radioactive_bunnies'
class DeadletterWorker
  include RadioactiveBunnies::Worker
  from_queue 'deadletter.worker', timeout_job_after: 5, prefetch: 1, threads: 1
  def work(metadata, msg)
    logger.info "Deadletter received with #{metadata.inspect} and payload #{msg.inspect}"
    true
  end
end

