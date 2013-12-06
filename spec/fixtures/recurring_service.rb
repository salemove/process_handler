require 'rubygems'
require 'bundler'
Bundler.setup

require 'salemove/process_handler/recurring_process'

class RecurringService
  def call
    puts "RESULT"
  end
end

service = RecurringService.new

process = Salemove::ProcessHandler::RecurringProcess.new(refractory_period: 1)
process.spawn(service)
