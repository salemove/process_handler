module Salemove
  module ProcessHandler
    class ProcessMonitor
      def spawn
        identifier = rand(10000)
        Thread.new { yield(identifier) }
      end

      def start
        init_signal_handlers
        @running = true
      end

      def stop
        @running = false
      end

      def running?
        !!@running
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

      # Interrupts a process. (The default action is to terminate gracefully).
      def init_int_signal
        trap :INT do
          puts 'Exiting process gracefully!'
          stop
        end
      end

      # Terminates a process immediately.
      def init_term_signal
        trap :TERM do
          exit
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
