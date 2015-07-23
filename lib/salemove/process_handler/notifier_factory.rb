require 'airbrake'
require 'growl'
require 'terminal-notifier'

module Salemove
  module ProcessHandler
    class NotifierFactory

      def self.get_notifier(env, process_name, conf)
        if conf && conf[:type] == 'airbrake'
          Airbrake.configure do |airbrake|
            airbrake.async = true
            airbrake.environment_name = env
            airbrake.host = conf.fetch(:host)
            airbrake.api_key = conf.fetch(:api_key)
          end
          Airbrake
        elsif conf && conf[:type] == 'growl'
          GrowlNotifier.new(process_name)
        elsif conf && conf[:type] == 'terminal-notifier'
          TerminalNotifierWrapper.new(process_name)
        end
      end
    end

    class GrowlNotifier
      def initialize(process_name)
        @process_name = process_name
      end

      def notify_or_ignore(error, _)
        Growl.notify error.message, title: "Error in #{@process_name}"
      end
    end

    class TerminalNotifierWrapper
      def initialize(process_name)
        @process_name = process_name
      end

      def notify_or_ignore(error, _)
        TerminalNotifier.notify(error, title: "Error in #{@process_name}")
      end
    end
  end
end
