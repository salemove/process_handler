require 'logger'
require 'benchmark'
require_relative 'process_monitor'
require_relative 'notifier_factory'

module Salemove
  module ProcessHandler
    class PivotProcess

      DEFAULT_FULFILLABLE_TIMEOUT = 3

      attr_reader :process_monitor, :exception_notifier

      def self.logger
        @logger ||= Logger.new(STDOUT).tap { |l| l.level = Logger::INFO }
      end

      def self.logger=(logger)
        @logger = logger
      end

      def initialize(messenger,
                     env: 'development',
                     notifier: nil,
                     notifier_factory: NotifierFactory,
                     process_monitor: ProcessMonitor.new)
        @messenger = messenger
        @process_monitor = process_monitor
        @exception_notifier = notifier_factory.get_notifier(env, notifier)
      end

      def spawn(service, blocking: true)
        @process_monitor.start

        @service_thread = ServiceSpawner.spawn(service, @messenger, @exception_notifier)
        blocking ? wait_for_monitor : Thread.new { wait_for_monitor }
      end

      private

      def wait_for_monitor
        sleep 1 while @process_monitor.running?
        @service_thread.shutdown
        @service_thread.join
        @process_monitor.shutdown
      end

      class ServiceSpawner
        def self.spawn(service, messenger, exception_notifier)
          new(service, messenger, exception_notifier).spawn
        end

        def initialize(service, messenger, exception_notifier)
          @service = service
          @messenger = messenger
          @exception_notifier = exception_notifier
        end

        def spawn
          @messenger.respond_to(@service.class::QUEUE) do |input, handler|
            response = handle_request(input)
            if response.respond_to?(:fulfilled?)
              handle_fulfillable_response(handler, response)
            else
              handle_response(handler, response)
            end
          end
        end

        def handle_fulfillable_response(handler, response)
          timeout = response.respond_to?(:timeout) && response.timeout || DEFAULT_FULFILLABLE_TIMEOUT
          Timeout::timeout(timeout) do
            while true
              if response.fulfilled?
                return handle_response(handler, response.value)
              end
              sleep 0.001
            end
          end
        rescue Timeout::Error
          handle_response(handler, success: false, error: "Fulfillable response was not fulfilled")
        end

        def handle_response(handler, response)
          if response.is_a?(Hash) && (response[:success] == false || response[:error])
            handler.error(response)
          else
            handler.success(response)
          end
        end

        def handle_request(input)
          if input.has_key?(:ping)
            { success: true, pong: 'pong' }
          else
            delegate_to_service(input)
          end
        rescue => exception
          handle_exception(exception, input)
        end

        def delegate_to_service(input)
          result = benchmark(input) { @service.call(input) }
          PivotProcess.logger.info "Result: #{result.inspect}"
          result
        end

        def handle_exception(e, input)
          PivotProcess.logger.error(e.inspect + "\n" + e.backtrace.join("\n"))
          if @exception_notifier
            @exception_notifier.notify_or_ignore(e, cgi_data: ENV.to_hash, parameters: input)
          end
          { success: false, error: e.message }
        end

        def benchmark(input, &block)
          type = input[:type] if input.is_a?(Hash)
          result = nil

          bm = Benchmark.measure { result = block.call }
          if defined?(Logasm) && PivotProcess.logger.is_a?(Logasm)
            PivotProcess.logger.debug "Execution time",
              type: type, real: bm.real, user: bm.utime, system: bm.stime
          end

          result
        end
      end
    end
  end
end
