require_relative 'process_monitor'

module Salemove
  module ProcessHandler
    class PivotProcess
      def initialize(messenger, threads_count: 1, process_monitor: ProcessMonitor.new)
        @messenger = messenger
        @threads_count = threads_count
        @process_monitor = process_monitor
      end

      def spawn(service)
        @process_monitor.start

        responders = (1..@threads_count).map {
          ServiceSpawner.spawn(@process_monitor, service, @messenger)
        }

        sleep 1 while @process_monitor.running?

        responders.each(&:cancel)
      end

      class ServiceSpawner
        def self.spawn(process_monitor, service, messenger)
          new(process_monitor, service, messenger).spawn
        end

        def initialize(process_monitor, service, messenger)
          @process_monitor = process_monitor
          @service = service
          @messenger = messenger
        end

        def spawn
          @messenger.respond_to(@service.class::QUEUE) do |input, handler|
            result = @service.call(input)
            puts "Result: #{result.inspect}"
            handler.ack(result)
          end
        end
      end
    end
  end
end
