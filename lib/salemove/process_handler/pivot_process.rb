require 'benchmark'
require 'securerandom'
require 'timeout'
require_relative 'process_monitor'
require_relative 'notifier_factory'

module Salemove
  module ProcessHandler
    class PivotProcess

      DEFAULT_FULFILLABLE_TIMEOUT = 3
      DEFAULT_EXECUTION_TIME_KEY = 'service.execution_time'.freeze

      attr_reader :process_monitor, :exception_notifier

      def initialize(freddy:,
                     logger:,
                     statsd:,
                     notifier: nil,
                     notifier_factory: NotifierFactory,
                     process_monitor: ProcessMonitor.new,
                     process_name: 'Unknown process',
                     log_error_as_string: false,
                     execution_time_key: DEFAULT_EXECUTION_TIME_KEY,
                     exit_enforcer: nil)
        @freddy = freddy
        @logger = logger
        @benchmarker = Benchmarker.new(
          statsd: statsd,
          application: process_name,
          execution_time_key: execution_time_key
        )
        @process_monitor = process_monitor
        @exception_notifier = notifier_factory.get_notifier(process_name, notifier)
        # Needed for forcing exit from jruby with exit(0)
        @exit_enforcer = exit_enforcer || Proc.new {}
        @log_error_as_string = log_error_as_string
      end

      def spawn(service, blocking: true)
        @process_monitor.start

        @service_threads = spawn_queue_threads(service).concat(spawn_tap_threads(service))
        blocking ? wait_for_monitor : Thread.new { wait_for_monitor }
      end

      def spawn_queue_threads(service)
        if service.class.const_defined?(:QUEUE)
          [
            ServiceSpawner.new(
              service,
              freddy: @freddy,
              logger: @logger,
              benchmarker: @benchmarker,
              exception_notifier: @exception_notifier,
              log_error_as_string: @log_error_as_string
            ).spawn
          ]
        else
          []
        end
      end

      def spawn_tap_threads(service)
        if service.class.const_defined?(:TAPPED_QUEUES)
          service.class::TAPPED_QUEUES.map do |queue|
            spawner = TapServiceSpawner.new(
              service,
              freddy: @freddy,
              logger: @logger,
              benchmarker: @benchmarker,
              exception_notifier: @exception_notifier
            )
            spawner.spawn(queue)
          end
        else
          []
        end
      end

      private


      def wait_for_monitor
        sleep 1 while @process_monitor.running?
        @service_threads.each(&:shutdown)
        @process_monitor.shutdown
        @exit_enforcer.call
      end

      class TapServiceSpawner
        def initialize(service, freddy:, logger:, benchmarker:, exception_notifier:)
          @service = service
          @freddy = freddy
          @logger = logger
          @benchmarker = benchmarker
          @exception_notifier = exception_notifier
        end

        def spawn(queue)
          @freddy.tap_into(queue) do |input|
            delegate_to_service(input.merge(type: queue))
          end
        end

        def delegate_to_service(input)
          @logger.info 'Received request', input
          @benchmarker.call(input) { @service.call(input) }
        rescue StandardError => exception
          handle_exception(exception, input)
        end

        def handle_exception(exception, input)
          message = [exception.inspect, *exception.backtrace].join("\n")
          @logger.error(message, input)

          @exception_notifier.notify_or_ignore(exception, input) if @exception_notifier
        end
      end

      class ServiceSpawner
        PROCESSED_REQUEST_LOG_KEYS = [:error, :success]

        def initialize(service, freddy:, logger:, benchmarker:, exception_notifier:, log_error_as_string:)
          @service = service
          @freddy = freddy
          @logger = logger
          @benchmarker = benchmarker
          @exception_notifier = exception_notifier
          @log_error_as_string = log_error_as_string
        end

        def spawn
          @freddy.respond_to(@service.class::QUEUE) do |input, handler|
            response = handle_request(input)
            if response.respond_to?(:fulfilled?)
              handle_fulfillable_response(input, handler, response)
            else
              handle_response(handler, response)
            end
          end
        end

        def handle_fulfillable_response(input, handler, response)
          timeout = response.respond_to?(:timeout) && response.timeout || DEFAULT_FULFILLABLE_TIMEOUT
          Timeout::timeout(timeout) do
            while true
              if response.fulfilled?
                log_processed_request(input, response.value)
                return handle_response(handler, response.value)
              end
              sleep 0.001
            end
          end
        rescue Timeout::Error
          @logger.error "Fullfillable response was not fulfilled in #{timeout} seconds", input
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
          @logger.info 'Received request', input
          if input.has_key?(:ping)
            { success: true, pong: 'pong' }
          else
            delegate_to_service(input)
          end
        rescue StandardError => exception
          handle_exception(exception, input)
        end

        def delegate_to_service(input)
          result = @benchmarker.call(input) { @service.call(**input) }

          unless result.respond_to?(:fulfilled?)
            log_processed_request(input, result)
          end

          result
        end

        def log_processed_request(input, result)
          attributes = result
            .select { |k, _| PROCESSED_REQUEST_LOG_KEYS.include?(k) }
            .merge(input)

          if @log_error_as_string
            attributes[:error] = attributes[:error].to_s if attributes.has_key?(:error)
          end

          @logger.info 'Processed request', attributes
        end

        def handle_exception(exception, input)
          message = [exception.inspect, *exception.backtrace].join("\n")
          @logger.error(message, input)

          @exception_notifier.notify_or_ignore(exception, input) if @exception_notifier

          { success: false, error: exception.message }
        end
      end

      class Benchmarker
        def initialize(statsd:, application:, execution_time_key:)
          @statsd = statsd
          @application = application
          @execution_time_key = execution_time_key
        end

        def call(input, &block)
          type = input[:type] if input.is_a?(Hash)
          result = nil

          bm = Benchmark.measure { result = block.call }

          @statsd.histogram(@execution_time_key, bm.real, tags: [
            "application:#{@application}",
            "type:#{type || 'unknown'}"
          ])

          result
        end
      end
    end
  end
end
