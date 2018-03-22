require 'logasm'
require 'spec_helper'
require 'salemove/process_handler/pivot_process'

describe ProcessHandler::PivotProcess do
  let(:monitor) { double('Monitor') }
  let(:freddy) { double('Freddy') }
  let(:statsd) { spy('Statsd') }
  let(:handler) { double('Handler') }
  let(:thread) { double('Thread') }
  let(:notifier_factory) { double('NotifierFactory') }
  let(:responder) { double(shutdown: true) }
  let(:logger) { Logasm.build('test-app', []) }
  let(:application) { 'my-app' }
  let(:log_error_as_string) { false }

  let(:process) do
    ProcessHandler::PivotProcess.new(
      freddy: freddy,
      logger: logger,
      statsd: statsd,
      process_monitor: monitor,
      process_name: application,
      notifier_factory: notifier_factory,
      log_error_as_string: log_error_as_string
    )
  end

  def expect_monitor_to_behave
    expect(monitor).to receive(:start)
    expect(monitor).to receive(:running?) { false }
    expect(monitor).to receive(:shutdown)
  end

  before do
    allow(notifier_factory).to receive(:get_notifier) { nil }
    expect_monitor_to_behave
  end

  describe 'responding services' do
    class ResultService
      QUEUE = 'Dummy'
    end

    subject { process.spawn(service) }
    let(:service) { ResultService.new }

    let(:input) {{}}
    let(:result) { {success: true, result: 'RESULT'} }

    def expect_handler_thread_to_behave
      allow(handler).to receive(:success) { thread }
      allow(handler).to receive(:error) { thread }
      expect(responder).to receive(:shutdown)
    end

    def expect_message
      expect(freddy).to receive(:respond_to) {|destination, &callback|
        callback.call(input, handler)
      }.and_return(responder)
    end

    before do
      expect_message
      expect_handler_thread_to_behave
      allow(service).to receive(:call).with(input) { result }
    end

    describe 'when service responds correctly' do

      it 'can be executed with logger' do
        expect(handler).to receive(:success).with(result)
        expect(service).to receive(:call).with(input)
        subject()
      end

      it 'records execution time' do
        expect(statsd).to receive(:histogram)
          .with(
            'service.execution_time',
            instance_of(Float),
            tags: ["application:#{application}", "type:unknown"]
          )
        subject()
      end
    end

    describe 'when service responds with an error' do
      let(:result) { { success: false, error: 'hey' } }

      before do
        expect(service).to receive(:call).with(input) { result }
      end

      it 'acks the message properly' do
        expect(handler).to receive(:error).with(result)
        subject()
      end
    end

    describe 'when service responds with an error object' do
      let(:result) { { success: false, error: {error: 'hey', message: 'message' } } }

      before do
        expect(service).to receive(:call).with(input) { result }
      end

      it 'logs the message as an object' do
        expect(logger).to receive(:info).with("Received request", {})
        expect(logger).to receive(:info)
          .with(
            "Processed request",
            { success: false, error: {error: 'hey', message: 'message'}, type: nil }
          )
        subject()
      end

      describe 'when log_error_as_string' do
        let(:log_error_as_string) { true }

        it 'logs the message as string' do
          expect(logger).to receive(:info).with("Received request", {})
          expect(logger).to receive(:info)
            .with(
              "Processed request",
              { success: false, error: "{:error=>\"hey\", :message=>\"message\"}", type: nil }
            )
          subject()
        end
      end
    end

    shared_examples 'an error_handler' do

      it 'logs error' do
        expect(logger).to receive(:error)
        subject()
      end

      describe 'with exception_notifier' do

        let(:exception_notifier) { double('Airbrake') }

        before do
          allow(notifier_factory).to receive(:get_notifier) { exception_notifier }
        end

        it 'triggers exception_notifier' do
          expect(exception_notifier).to receive(:notify_or_ignore)
          subject()
        end
      end

    end

    describe 'when service raises exception' do

      let(:result) { { success: false, error: exception } }
      let(:exception) { "what an unexpected exception!" }

      before do
        expect(service).to receive(:call).with(input) { raise exception }
      end

      it 'acks the message properly' do
        expect(handler).to receive(:error).with(result)
        subject()
      end

      it_behaves_like 'an error_handler'

    end

    describe 'when result is fulfillable' do
      let(:result) { double }

      context 'and its already fulfilled' do
        let(:value) { { success: true, output: { result: 'R'} } }

        before do
          allow(result).to receive(:fulfilled?) { true }
          allow(result).to receive(:value) { value }
        end

        it 'responds immediately' do
          expect(handler).to receive(:success).with(value)
          subject()
        end
      end

      context 'and its fulfilled later' do
        let(:value) { { success: true, output: { result: 'R'} } }

        before do
          allow(result).to receive(:fulfilled?) { false }
          Thread.new do
            sleep 0.005
            allow(result).to receive(:fulfilled?) { true }
            allow(result).to receive(:value) { value }
          end
        end

        it 'responds when fulfilled' do
          expect(handler).to receive(:success).with(value)
          subject()
        end
      end

      context 'and its never fulfilled' do

        let(:timeout) { 0.001 }

        before do
          allow(result).to receive(:fulfilled?) { false }
          allow(result).to receive(:timeout) { timeout }
        end

        it 'responds with timeout error' do
          expect(handler).to receive(:error).with(success: false, error: "Fulfillable response was not fulfilled")
          subject
        end

        it 'logs the error' do
          expect(logger).to receive(:error).with("Fullfillable response was not fulfilled in #{timeout} seconds", {})
          subject
        end
      end
    end
  end

  describe 'tapping services' do
    class TappingService
      TAPPED_QUEUES = [
        'one',
        'two'
      ]
    end

    subject { process.spawn(service) }
    let(:service) { TappingService.new }
    let(:tap_count) { TappingService::TAPPED_QUEUES.count }

    let(:input) {{}}

    def expect_tap_into
      expect(freddy).to receive(:tap_into) do |destination, &callback|
        callback.call(input)
      end
        .exactly(tap_count).times
        .and_return(responder)
    end

    before do
      expect_tap_into
      expect(responder).to receive(:shutdown)
      allow(service).to receive(:call).with(input)
    end

    describe 'when service handles the input correctly' do
      it 'can be executed' do
        expect(service).to receive(:call).with(input.merge(type: 'one'))
        expect(service).to receive(:call).with(input.merge(type: 'two'))
        subject()
      end
    end

    shared_examples 'an error_handler' do
      it 'logs error' do
        expect(logger).to receive(:error)
        subject()
      end

      describe 'with exception_notifier' do

        let(:exception_notifier) { double('Airbrake') }

        before do
          allow(notifier_factory).to receive(:get_notifier) { exception_notifier }
        end

        it 'triggers exception_notifier' do
          expect(exception_notifier).to receive(:notify_or_ignore)
          subject()
        end
      end

    end

    describe 'when service raises exception' do
      let(:exception) { "what an unexpected exception!" }

      before do
        expect(service).to receive(:call).with(input.merge(type: 'one')) {}
        expect(service).to receive(:call).with(input.merge(type: 'two')) { raise exception }
      end

      it_behaves_like 'an error_handler'
    end

  end
end
