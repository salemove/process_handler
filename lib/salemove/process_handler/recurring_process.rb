require_relative 'process_monitor'

module Salemove
  module ProcessHandler
    class RecurringProcess
      def initialize(refractory_period: 5)
        @refractory_period = refractory_period
      end

      def spawn(service)
        process_monitor = ProcessMonitor.run

        while process_monitor.running?
          service.call
          sleep @refractory_period
        end

        puts 'All done... Bye!'
      end
    end
  end
end
