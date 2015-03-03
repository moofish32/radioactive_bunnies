require 'frenzy_bunnies'
module Subdomain
  class RightNameWorker
    include FrenzyBunnies::Worker
    from_queue 'dummy.worker'
    def work(metadata, msg)
      true
    end
  end
end
