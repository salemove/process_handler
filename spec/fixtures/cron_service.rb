require 'salemove/process_handler/cron_process'

module Salemove 

  class EchoResultService
    def call
      puts "RESULT"
    end
  end

  ProcessHandler::CronProcess.new('1').spawn(EchoResultService.new)

end