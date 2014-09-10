require 'salemove/process_handler/cron_process'

module Salemove

  class EchoResultService
    def call
      puts "RESULT"
    end
  end

  cron_process = ProcessHandler::CronProcess.new
  cron_process.schedule('0.5')
  cron_process.spawn(EchoResultService.new, blocking: true)

end