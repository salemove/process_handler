require 'rufus-scheduler'
require_relative 'cron_process_monitor'

module Salemove
  module ProcessHandler
    class CronProcess

      # @param [String] expression
      #   can either be a any cron expression like every five minutes: '5 * * * *'
      #   or interval like '1' for seconds, '2h' for hours and '2d' for days
      # @param [Boolean] join
      #   whether to block the main thread while scheduler is running (similarily to RecurringProcess)
      def initialize(join: true)
        @join = join
        @spawned_any = false
        @scheduler = Rufus::Scheduler.new
      end

      def spawn(expression, service)
        @spawned_any = true
        CronProcessMonitor.new(self).start
        @scheduler.repeat expression, service
        @scheduler.join if @join
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
