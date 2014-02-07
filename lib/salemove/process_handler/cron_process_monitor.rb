require_relative 'process_monitor'

module Salemove
  module ProcessHandler
    class CronProcessMonitor < ProcessMonitor

      def initialize(process)
        @process = process
      end

      def stop
        super
        @process.stop
      end

    end
  end
end
