require 'salemove/process_handler'
require 'salemove/process_handler/composite_process'
require 'salemove/process_handler/cron_process'
require 'salemove/process_handler/pivot_process'

module Salemove

  class EchoResultService
    QUEUE = 'Dummy'

    def call(params={})
      puts "RESULT"
    end
  end

  class Freddy
    def respond_to(*)
      ResponderHandler.new
    end
  end

  class DummyStatsd
    def histogram(*)
    end
  end

  class ResponderHandler
    def shutdown
    end
  end

  cron_process = ProcessHandler::CronProcess.new
  cron_process.schedule('0.5')
  cron_process.schedule('5', some: 'params')

  pivot_process = ProcessHandler::PivotProcess.new(
    freddy: Freddy.new,
    logger: Logger.new('/dev/null'),
    statsd: DummyStatsd.new
  )

  ProcessHandler.start_composite do
    add cron_process, EchoResultService.new
    add pivot_process, EchoResultService.new
  end

end
