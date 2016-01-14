require 'spec_helper'
require 'salemove/process_handler/composite_process'

describe ProcessHandler::CompositeProcess do

  it 'can be gracefully stopped with SIGINT' do
    result = run_and_signal_fixture(fixture: 'composite_service.rb', signal: 'INT', sleep_period: 1)
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

  it 'can be gracefully stopped with SIGTERM' do
    result = run_and_signal_fixture(fixture: 'composite_service.rb', signal: 'TERM', sleep_period: 1)
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

end
