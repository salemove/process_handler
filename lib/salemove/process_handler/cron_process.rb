require 'rufus-scheduler'
require_relative 'cron_process_monitor'

module Salemove
  module ProcessHandler
    class CronProcess

      # @param [String] expression
      #   can either be a any cron expression like every five minutes: '5 * * * *'
      #   or interval like '1' for seconds, '2h' for hours and '2d' for days
      def initialize
        @spawned_any = false
        @scheduler = Rufus::Scheduler.new
      end

      def start_monitor
        CronProcessMonitor.new(self).start
      end

      def spawn(expression, service, params=nil)
        @spawned_any = true
        if params.nil?
          @scheduler.repeat expression, service
        else
          @scheduler.repeat expression do
            service.call(params)
          end
        end
      end

      def join
        @scheduler.join if @spawned_any
      end

      def stop
        #Separate thread to avoid Ruby 2.0+ trap context 'synchronize' exception
        Thread.new { @scheduler.shutdown(:wait) }
      end

    end
  end
end
