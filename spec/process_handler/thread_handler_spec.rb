require 'spec_helper'
require 'salemove/process_handler/thread_handler'

describe ProcessHandler::ThreadHandler do
  describe '#stop' do
    context 'when stop signal callback is defined' do
      it 'invokes the callback' do
        result = nil

        handler = described_class.new(1)
        handler.start {}
        handler.on_stop_signal do
          result = 'called'
        end
        handler.stop

        expect(result).to eq('called')
        expect(handler.stopped?).to be(true)
      end
    end

    context 'when thread is processing' do
      it 'waits until processing is finished' do
        worker = Class.new do
          def start(thread)
            thread.mark_as_processing
            @thread = thread
          end

          def finish
            @thread.mark_as_idle
          end
        end.new

        handler = described_class.handle do |thread|
          worker.start(thread)
        end
        sleep 0.1

        handler.stop
        expect(handler.stopped?).to be(false)

        # emulate worker finished
        worker.finish

        handler.stop
        expect(handler.stopped?).to be(true)
      end
    end
  end
end
