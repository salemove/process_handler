require 'airbrake'

module Salemove
  module ProcessHandler
    class NotifierFactory

      def self.get_notifier(env, conf)
        if conf && conf[:type] == 'airbrake'
          Airbrake.configure do |airbrake|
            airbrake.async = true
            airbrake.environment_name = env
            airbrake.host = conf.fetch(:host)
            airbrake.api_key = conf.fetch(:api_key)
          end
        end
      end     

    end
  end
end
