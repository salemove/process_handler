require_relative 'process_monitor'

module Salemove
  module ProcessHandler
    class RecurringProcess
      def initialize(refractory_period: 5, process_monitor: ProcessMonitor.new)
        @refractory_period = refractory_period
        @process_monitor = process_monitor
      end

      def spawn(service)
        @process_monitor.start

        while @process_monitor.running?
          service.call
          relax
        end

        puts 'All done... Bye!'
      end

      private

      def relax
        @refractory_period.times { sleep 1 }
      end
    end
  end
end
