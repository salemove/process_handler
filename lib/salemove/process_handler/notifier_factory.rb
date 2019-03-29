module Salemove
  module ProcessHandler
    class NotifierFactory
      def self.get_notifier(process_name, conf)
        return nil unless conf

        case conf[:type]
        when 'airbrake'
          AirbrakeNotifier.new
        when 'sentry'
          SentryNotifier.new
        when 'growl'
          GrowlNotifier.new(process_name)
        when 'terminal-notifier'
          TerminalNotifierWrapper.new(process_name)
        end
      end
    end

    class AirbrakeNotifier
      def notify_or_ignore(error, params)
        Airbrake.notify(error, params)
      end
    end

    class SentryNotifier
      def notify_or_ignore(error, params)
        Raven.capture_exception(error, extra: params)
      end
    end

    class GrowlNotifier
      def initialize(process_name)
        @process_name = process_name
      end

      def notify_or_ignore(error, _)
        Growl.notify(error.message, title: "Error in #{@process_name}")
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
