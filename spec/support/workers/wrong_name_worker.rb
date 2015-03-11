require 'radioactive_bunnies'
module Subdomain
  class RightNameWorker
    include RadioactiveBunnies::Worker
    from_queue 'dummy.worker'
    def work(metadata, msg)
      true
    end
  end
end
