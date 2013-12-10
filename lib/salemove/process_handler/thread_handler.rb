module Salemove
  module ProcessHandler
    class ThreadHandler
      def self.handle(&block)
        identifier = rand(10000)
        handler = new(identifier)
        handler.start(&block)
        handler
      end

      def initialize(identifier)
        @identifier = identifier
        @stopped = true
        @processing = false
      end

      attr_reader :identifier

      def start(&block)
        @stopped = false
        @thread = Thread.new { block.call(self) }
        @thread
      end

      def join
        @thread.join
      end

      def on_stop_signal(&block)
        @stop_signal_cb = block
      end

      def stop
        @stop_signal_cb && @stop_signal_cb.call
        @stopping = true

        if idle?
          @stopped = true
        else
          Thread.new do
            sleep 0.1 until idle?
            @stopped = true
          end
        end
      end

      def stopped?
        !!@stopped
      end

      def mark_as_processing
        @processing = true
      end

      def mark_as_idle
        @processing = false
      end

      def idle?
        !@processing
      end
    end
  end
end
