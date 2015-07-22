require 'rufus-scheduler'
require_relative 'cron_process_monitor'
require_relative 'notifier_factory'

module Salemove
  module ProcessHandler

    class CronScheduler < Rufus::Scheduler

      def initialize(exception_notifier, options)
        super options
        @exception_notifier = exception_notifier
      end

      def on_error(job, error)
        if @exception_notifier
          @exception_notifier.notify_or_ignore(error, cgi_data: ENV.to_hash)
        end
        super
      end

    end

    class CronProcess

      attr_reader :process_monitor

      def initialize(env: 'development',
                     notifier: nil,
                     notifier_factory: NotifierFactory,
                     scheduler_options: {})
        @schedules = []
        @exception_notifier = notifier_factory.get_notifier(env, 'Cron Process', notifier)
        @scheduler = CronScheduler.new @exception_notifier, scheduler_options
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
