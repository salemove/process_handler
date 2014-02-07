require 'salemove/process_handler/recurring_process'

module Salemove 

  class EchoResultService
    def call
      puts "RESULT"
    end
  end

  ProcessHandler::RecurringProcess.new(refractory_period: 1).spawn(EchoResultService.new)
end
