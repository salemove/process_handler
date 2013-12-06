require 'spec_helper'
require 'salemove/process_handler/recurring_process'

describe ProcessHandler::RecurringProcess do
  it 'can be gracefully stopped' do
    output_read, output_write = IO.pipe

    pid = Process.spawn('ruby ' + fixture_path('recurring_service.rb'), out: output_write)
    sleep 1.5
    Process.kill('INT', pid)
    Process.wait2(pid)
    output_write.close

    result = output_read.read

    expect(result).to eq("RESULT\nRESULT\nExiting process gracefully!\nAll done... Bye!\n")
  end

  it 'can be terminated' do
    output_read, output_write = IO.pipe

    pid = Process.spawn('ruby ' + fixture_path('recurring_service.rb'), out: output_write)
    sleep 1.5
    Process.kill('TERM', pid)
    Process.wait2(pid)
    output_write.close

    result = output_read.read

    expect(result).to eq("RESULT\nRESULT\n")
  end
end
