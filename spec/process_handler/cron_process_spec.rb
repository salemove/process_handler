require 'spec_helper'
require 'salemove/process_handler/cron_process'

describe ProcessHandler::CronProcess do

  it 'can be gracefully stopped' do
    result = run_and_signal_fixture('cron_service.rb','INT')
    expect(result).to eq("RESULT\nExiting process gracefully!\n")
  end

  it 'can be terminated' do
    result = run_and_signal_fixture('cron_service.rb','TERM')
    expect(result).to eq("RESULT\n")
  end

end
