module RadioactiveBunnies
  module DeadletterWorker

    def register_with_deadletter_worker(worker_class)
      deadletter_producers << worker_class.name
    end

    def deadletter_producers
      @dl_producers ||= []
    end

    def deadletter_init(worker_opts)
      return unless !!worker_opts[:deadletter_workers]
      [worker_opts[:deadletter_workers]].flatten.each do |worker|
        worker_klass = RadioactiveBunnies::Ext::Util.constantize!(worker)
        worker_klass.register_with_deadletter_worker(self)
      end
    end

    def self.deadletter_queue_config(q_opts)
      # check if deadletter workers are set
      # verify all workers only point to one exchange raise blow up don't start
      #    if more than one exchange
      # if deadletter workers exist build the arguments and return them
      # if they did not exist return emtpy hash to keep the merge happy
      # THIS is being called from queue_factory
      {arguments: {'x-dead-letter-exchange' => 'deadletter.exchange'}}
    end
  end
end
