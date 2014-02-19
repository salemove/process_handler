require 'salemove/process_handler/cron_process'

module Salemove

  class EchoResultService
    def call
      puts "RESULT"
    end
  end

  ProcessHandler::CronProcess.new.spawn('1', EchoResultService.new)

end