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

  it 'can be gracefully stopped' do
    result = run_and_signal_fixture(fixture: 'cron_service.rb', signal: 'INT', sleep_period: 1)
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

  it 'can be terminated' do
    result = run_and_signal_fixture(fixture: 'cron_service.rb', signal: 'TERM', sleep_period: 1)
    expect(result).to eq("RESULT\n")
  end

  describe 'scheduler' do
    let(:subject) { ProcessHandler::CronProcess.new(frequency: 0.1) }
    let(:messages) { [] }
    let(:queue) { Queue.new }

    it 'does not trigger 2 jobs at once' do
      subject.schedule('0.1', 'first')
      subject.schedule('0.4', 'second')
      Thread.new do
        subject.spawn(AppenderService.new(messages, queue))
      end
       # block main thread until 3 schedules have run
      (1..3).map { queue.pop }
      expect(messages).to eq(['first', 'second', 'first'])
    end

  end

end
