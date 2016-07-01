require 'spec_helper'
require 'salemove/process_handler/cron_process'

describe ProcessHandler::CronProcess do

  class AppenderService

    def initialize(messages, queue)
      @messages = messages
      @queue = queue
    end

    def call(name)
      @messages << name
      @queue << nil # unblock main thread
      sleep 0.4 # simulate expense
    end

  end

  class ExceptionService

    def initialize(queue)
      @queue = queue
    end

    def call
      raise "A Runtimino Exceptino"
    ensure
      @queue << nil # unblock main thread
    end
  end

  it 'can be gracefully stopped with SIGINT' do
    result = run_and_signal_fixture(fixture: 'cron_service.rb', signal: 'INT', sleep_period: 1)
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

  it 'can be gracefully stopped with SIGTERM' do
    result = run_and_signal_fixture(fixture: 'cron_service.rb', signal: 'TERM', sleep_period: 1)
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

  describe 'scheduler' do
    let(:process) { ProcessHandler::CronProcess.new(scheduler_options: {frequency: 0.1}) }
    let(:messages) { [] }
    let(:queue) { Queue.new }

    it 'does not trigger 2 jobs at once' do
      process.schedule('0.1', 'first')
      process.schedule('0.4', 'second')
      Thread.new do
        process.spawn(AppenderService.new(messages, queue))
      end
       # block main thread until 3 schedules have run
      (1..3).map { queue.pop }
      expect(messages).to eq(['first', 'second', 'first'])
    end

  end

  describe 'exception handler' do
    let(:process) { ProcessHandler::CronProcess.new(params) }
    let(:params) {{ env: 'test', notifier_factory: notifier_factory,
      scheduler_options: {frequency: 0.2} }}
    let(:notifier_factory) { double('NotifierFactory') }
    let(:exception_notifier) { double('Airbrake') }
    let(:queue) { Queue.new }

    before(:each) do
      allow(notifier_factory).to receive(:get_notifier) { exception_notifier }
    end

    it 'notifies of exception' do
      process.schedule('0.3')
      expect(exception_notifier).to receive(:notify_or_ignore)
      Thread.new do
        process.spawn(ExceptionService.new(queue))
      end
      queue.pop
    end

  end

end
