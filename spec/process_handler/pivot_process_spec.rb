require 'logger'
require 'spec_helper'
require 'salemove/process_handler/pivot_process'

class ResultService
  QUEUE = 'Dummy'
end

describe ProcessHandler::PivotProcess do
  let(:monitor)   { double('Monitor') }
  let(:messenger) { double('Messenger') }
  let(:handler)   { double('Handler') }
  let(:thread)    { double('Thread') }

  subject { process.spawn(service) }
  let(:service) { ResultService.new }

  let(:process) { ProcessHandler::PivotProcess.new(messenger, process_params) }
  let(:process_params) {{ process_monitor: monitor , notifier_factory: notifier_factory, env: 'test' }}
  let(:notifier_factory) { double('NotifierFactory') }

  let(:input) {{}}
  let(:result) { {success: true, result: 'RESULT'} }

  let(:logger) { Logger.new('/dev/null') }

  def expect_monitor_to_behave
    expect(monitor).to receive(:start)
    expect(monitor).to receive(:running?) { false }
    expect(monitor).to receive(:shutdown)
  end

  def expect_message
    expect(messenger).to receive(:respond_to) do |destination, &callback|
      callback.call(input, handler)
    end
  end

  def expect_handler_thread_to_behave
    allow(handler).to receive(:ack) { thread }
    expect(thread).to receive(:shutdown)
    expect(thread).to receive(:join)
  end

  before do
    ProcessHandler::PivotProcess.logger = logger
    allow(notifier_factory).to receive(:get_notifier) { nil }
    expect_monitor_to_behave
    expect_message
    expect_handler_thread_to_behave
    allow(service).to receive(:call).with(input) { result }
  end

  describe 'when service responds correctly' do

    it 'can be executed with logger' do
      expect(handler).to receive(:ack).with(result)
      expect(service).to receive(:call).with(input)
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
      expect(service).to receive(:call).with(input) { raise exception }
    end

    it 'acks the message properly' do
      expect(handler).to receive(:ack).with(result)
      subject()
    end

    it_behaves_like 'an error_handler'

  end

  describe 'when exception raises after service call' do

    let(:result) { { success: false, output: exception } }
    let(:exception) { "no no no ... no inspect for you!" }

    before do
      expect(result).to receive(:inspect) { raise exception }
    end

    it 'still acks the message properly' do
      subject()
    end

    it_behaves_like 'an error_handler'

  end

end
