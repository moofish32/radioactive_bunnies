module RadioactiveBunnies
  module DeadletterWorker
    module ClassMethods
      def register_with_deadletter_worker(worker_class)
        deadletter_producers << worker_class.name
      end

      def deadletter_producers
        @dl_producers ||= []
      end

      def deadletter_init(worker_opts)
        return unless !!worker_opts[:deadletter_workers]
        worker_list = [worker_opts[:deadletter_workers]].flatten
        exchanges = worker_list.inject([]) do |deadletter_exchange, worker|
          worker_klass = RadioactiveBunnies::Ext::Util.constantize!(worker)
          worker_klass.register_with_deadletter_worker(self)
          deadletter_exchange << worker_klass.queue_opts[:exchange][:name]
        end
        validate_deadletter_exchanges!(exchanges)
      end

      def validate_deadletter_exchanges!(exchanges)
        raise DeadletterError.multiple_exchanges(self, exchanges) unless 1 == exchanges.uniq.count
        raise DeadletterError.nil_exchange(self) if exchanges.include? nil
        self.deadletter_exchange = exchanges.first
      end

    end

    class << self
      def deadletter_queue_config(q_opts)
        return {} unless !!q_opts[:deadletter_exchange]
        {arguments: {'x-dead-letter-exchange' => q_opts[:deadletter_exchange]}}
      end
    end
  end
  class DeadletterError < StandardError
    def self.multiple_exchanges(klass, exchanges)
      new("Multiple deadletter exchanges in [#{klass.name}] - exchanges are <#{exchanges}>")
    end
    def self.nil_exchange(klass)
      new("Found nil for deadletter exchange name in [#{klass.name}]")
    end
  end
end
