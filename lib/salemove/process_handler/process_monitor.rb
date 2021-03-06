module Salemove
  module ProcessHandler
    class ProcessMonitor
      def start
        init_signal_handlers
        @state = :running
      end

      def stop
        @state = :stopping if alive?
      end

      def shutdown
        @state = :stopped
      end

      def running?
        @state == :running
      end

      def alive?
        @state != :stopped
      end

      private

      def init_signal_handlers
        init_hup_signal
        init_quit_signal
        init_int_signal
        init_term_signal
      end

      # Many daemons will reload their configuration files and reopen their
      # logfiles instead of exiting when receiving this signal.
      def init_hup_signal
        trap :HUP do
          puts 'SIGHUP: not implemented'
        end
      end

      # Terminates the process gracefully
      def init_int_signal
        trap :INT do
          puts 'Exiting process gracefully!'
          stop
        end
      end

      # Terminates the process gracefully
      def init_term_signal
        trap :TERM do
          puts 'Exiting process gracefully!'
          stop
        end
      end

      # Terminates a process. This is different from both SIGKILL and SIGTERM
      # in the sense that it generates a core dump of the process and also
      # cleans up resources held up by a process. Like SIGINT, this can also
      # be sent from the terminal as input characters.
      def init_quit_signal
        trap :QUIT do
          exit
        end
      end
    end
  end
end
