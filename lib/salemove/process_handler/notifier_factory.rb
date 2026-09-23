module Salemove
  module ProcessHandler
    class NotifierFactory
      def self.get_notifier(process_name, conf)
        return nil unless conf

        case conf[:type]
        when 'sentry'
          SentryNotifier.new
        when 'terminal-notifier'
          TerminalNotifierWrapper.new(process_name)
        end
      end
    end

    class SentryNotifier
      def notify_or_ignore(error, params)
        Raven.capture_exception(error, extra: params)
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
