require 'spec_helper'
require 'salemove/process_handler/recurring_process'

describe ProcessHandler::RecurringProcess do
    
  it 'can be gracefully stopped' do
    result = run_and_signal_fixture('recurring_service.rb','INT')
    expect(result).to eq("RESULT\nRESULT\nExiting process gracefully!\nAll done... Bye!\n")
  end

  it 'can be terminated' do
    result = run_and_signal_fixture('recurring_service.rb','TERM')
    expect(result).to eq("RESULT\nRESULT\n")
  end
end
