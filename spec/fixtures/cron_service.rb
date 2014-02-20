require 'salemove/process_handler/cron_process'

module Salemove

  class EchoResultService
    def call
      puts "RESULT"
    end
  end

  cron_process = ProcessHandler::CronProcess.new
  cron_process.spawn('1', EchoResultService.new)
  cron_process.start_monitor
  cron_process.join

end