require 'rufus-scheduler'
require_relative 'cron_process_monitor'

module Salemove
  module ProcessHandler
    class CronProcess

      attr_reader :process_monitor

      def initialize
        @schedules = []
        @scheduler = Rufus::Scheduler.new
        @process_monitor = CronProcessMonitor.new(self)
      end

      # @param [String] expression
      #   can either be a any cron expression like every five minutes: '5 * * * *'
      #   or interval like '1' for seconds, '2h' for hours and '2d' for days
      def schedule(expression, params={})
        @schedules << { expression: expression, params: params } 
      end

      def spawn(service, blocking: true)
        @process_monitor.start
        @schedules.each do |schedule|
          spawn_schedule(service, schedule)
        end
        @scheduler.join if blocking
      end

      def spawn_schedule(service, expression:, params:)
        if params.empty?
          @scheduler.repeat expression, service
        else
          @scheduler.repeat expression do
            service.call(params)
          end
        end
      end

      def stop
        #Separate thread to avoid Ruby 2.0+ trap context 'synchronize' exception
        Thread.new do
          @scheduler.shutdown(:wait)
          @process_monitor.shutdown
        end
      end

    end
  end
end
