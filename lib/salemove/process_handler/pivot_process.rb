require_relative 'process_monitor'

module Salemove
  module ProcessHandler
    class PivotProcess
      def initialize(messenger, opts = {})
        @messenger = messenger
        @threads_count = opts.fetch(:threads_count, 1)
      end

      def spawn(service)
        process_monitor = ProcessMonitor.run

        (1..@threads_count).map {
          ServiceSpawner.spawn(process_monitor, service, @messenger)
        }.each(&:join)
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
          @process_monitor.spawn do |identifier|
            start(identifier)
          end
        end

        def start(identifier)
          while @process_monitor.running?
            unless process(identifier)
              sleep 1
            end
          end

          puts "Exiting thread ##{identifier}"
        end

        def process(identifier)
          @messenger.process(@service.class) do |input|
            result = @service.call(input)
            puts "Process ##{identifier}: #{result.inspect}"
            result
          end
        end
      end
    end
  end
end
