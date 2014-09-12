require 'rufus-scheduler'
require_relative 'cron_process_monitor'

module Salemove
  module ProcessHandler
    class CronProcess

      attr_reader :process_monitor

      def initialize(scheduler_options={})
        @schedules = []
        @scheduler = Rufus::Scheduler.new scheduler_options
        @process_monitor = CronProcessMonitor.new(self)
      end

      # @param [String] expression
      #   can either be a any cron expression like every five minutes: '5 * * * *'
      #   or interval like '1' for seconds, '2h' for hours and '2d' for days
      def schedule(expression, params={}, overlap=false)
        @schedules << { expression: expression, params: params, overlap: overlap }
      end

      def spawn(service, blocking: true)
        @process_monitor.start
        @schedules.each do |schedule|
          spawn_schedule(service, schedule)
        end
        @scheduler.join if blocking
      end

      def spawn_schedule(service, expression:, params:, overlap:)
        if params.empty?
          @scheduler.repeat expression, {overlap: overlap} { service.call }
        else
          @scheduler.repeat expression, {overlap: overlap} { service.call(params) }
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
