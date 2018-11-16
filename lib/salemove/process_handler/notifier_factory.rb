require 'airbrake'
require 'growl'
require 'terminal-notifier'

module Salemove
  module ProcessHandler
    class NotifierFactory

      def self.get_notifier(process_name, conf)
        if conf && conf[:type] == 'airbrake'
          notifier_name = conf[:notifier_name] || :default
          Airbrake.configure(notifier_name) do |airbrake|
            airbrake.environment = conf.fetch(:environment)
            airbrake.host = conf.fetch(:host)
            airbrake.project_id = conf.fetch(:project_id)
            airbrake.project_key = conf.fetch(:project_key)
            airbrake.ignore_environments = conf[:ignore_environments] if conf[:ignore_environments]
            airbrake.whitelist_keys = [
              /_HOST$/, /_TCP$/, /_UDP$/, /_PROTO$/, /_ADDR$/, 'PWD',
              'GEM_HOME', 'PATH', 'SERVICE_NAME', 'RUBY_MAJOR', 'RUBY_VERSION',
              'RACK_ENV', 'RUN_ENV', 'HOME', 'RUBYGEMS_VERSION', 'BUNDLER_VERSION'
            ]
          end
          AirbrakeNotifier.new
        elsif conf && conf[:type] == 'growl'
          GrowlNotifier.new(process_name)
        elsif conf && conf[:type] == 'terminal-notifier'
          TerminalNotifierWrapper.new(process_name)
        end
      end
    end

    class AirbrakeNotifier
      def notify_or_ignore(error, params)
        Airbrake.notify(error, params)
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
