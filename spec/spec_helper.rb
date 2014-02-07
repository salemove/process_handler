require 'rubygems'
require 'bundler'
Bundler.setup

require 'rspec'
require 'salemove/process_handler'

include Salemove

RSpec.configure do
  def fixture_path(name)
    File.join(File.dirname(__FILE__), "fixtures", name)
  end

  def run_and_signal_fixture(fixture, signal)
    output_read, output_write = IO.pipe

    pid = Process.spawn('ruby ' + fixture_path(fixture), out: output_write)
    sleep 1.5
    Process.kill(signal, pid)
    Process.wait2(pid)
    output_write.close

    output_read.read
  end
end
