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

        (1..@threads_count).map {
          ServiceSpawner.spawn(@process_monitor, service, @messenger)
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
          @process_monitor.spawn do |thread_handler|
            start(thread_handler)
          end
        end

        private

        def start(thread_handler)
          responder_handler = process(thread_handler)
          thread_handler.on_stop_signal { responder_handler.cancel }

          sleep 1 until thread_handler.stopped?

          puts "Exiting thread ##{thread_handler.identifier}"
        end

        def process(thread_handler)
          @messenger.respond_to(@service.class::QUEUE) do |input, handler|
            thread_handler.mark_as_processing

            result = @service.call(input)
            puts "Process ##{thread_handler.identifier}: #{result.inspect}"
            handler.ack(result)

            thread_handler.mark_as_idle
          end
        end
      end
    end
  end
end
