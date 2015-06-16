require 'radioactive_bunnies'
class TimeoutWorker
  include RadioactiveBunnies::Worker
  from_queue 'timeout.worker',
    deadletter: 'RadioactiveBunnies::DeadletterWorker',
    timeout_job_after: 1,
    prefetch: 1,
    threads: 1

  def work(metadata, msg)
    while(true) do
    end
  end
end

