require 'logasm'
require 'spec_helper'
require 'salemove/process_handler/pivot_process'

describe ProcessHandler::PivotProcess do
  let(:monitor) { double('Monitor') }
  let(:freddy) { double('Freddy') }
  let(:handler) { double('Handler') }
  let(:thread) { double('Thread') }
  let(:process) { ProcessHandler::PivotProcess.new(freddy, process_params) }
  let(:process_params) {{ process_monitor: monitor , notifier_factory: notifier_factory}}
  let(:notifier_factory) { double('NotifierFactory') }
  let(:responder) { double(shutdown: true) }
  let(:logger) { Logasm.build('test-app', []) }

  def expect_monitor_to_behave
    expect(monitor).to receive(:start)
    expect(monitor).to receive(:running?) { false }
    expect(monitor).to receive(:shutdown)
  end

  before do
    ProcessHandler::PivotProcess.logger = logger
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
      allow(service).to receive(:call).with(input.merge(request_id: anything)) { result }
    end

    describe 'when service responds correctly' do

      it 'can be executed with logger' do
        expect(handler).to receive(:success).with(result)
        expect(service).to receive(:call).with(input.merge(request_id: anything))
        subject()
      end

    end

    describe 'when service responds with an error' do
      let(:result) { { success: false, error: 'hey' } }

      before do
        expect(service).to receive(:call).with(input.merge(request_id: anything)) { result }
      end

      it 'acks the message properly' do
        expect(handler).to receive(:error).with(result)
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

      let(:result) { { success: false, error: exception } }
      let(:exception) { "what an unexpected exception!" }

      before do
        expect(service).to receive(:call).with(input.merge(request_id: anything)) { raise exception }
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
        expect(service).to receive(:call).with(input.merge(type: 'one', request_id: anything))
        expect(service).to receive(:call).with(input.merge(type: 'two', request_id: anything))
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
        expect(service).to receive(:call).with(input.merge(type: 'one', request_id: anything)) {}
        expect(service).to receive(:call).with(input.merge(type: 'two', request_id: anything)) { raise exception }
      end

      it_behaves_like 'an error_handler'
    end

  end
end
