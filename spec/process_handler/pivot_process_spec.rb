require 'logger'
require 'spec_helper'
require 'salemove/process_handler/pivot_process'

class ResultService 
  QUEUE = 'Dummy'

  def call(input)
    "RESULT"
  end
end

describe ProcessHandler::PivotProcess do

    let!(:monitor) {double("Monitor")}
    let!(:messenger) {double("Messenger")}
    let!(:handler) {double("Handler")}
    let!(:thread) {double("Thread")}

    before do
      expect(monitor).to receive(:start)
      expect(monitor).to receive(:running?).and_return false
      expect(monitor).to receive(:shutdown)

      expect(messenger).to receive(:respond_to) do |destination, &callback|
        callback.call(nil, handler)
      end

      expect(handler).to receive(:ack).and_return(thread)
      expect(thread).to receive(:shutdown)
      expect(thread).to receive(:join)
    end

    it 'can be executed with logger' do
      ProcessHandler::PivotProcess.logger = Logger.new('/dev/null')
      process = ProcessHandler::PivotProcess.new(messenger, process_monitor: monitor)
      process.spawn(ResultService.new)
    end

end
