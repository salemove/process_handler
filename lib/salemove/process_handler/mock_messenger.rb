module Salemove
  module ProcessHandler
    class MockMessenger
      def respond_to(queue_name, &block)
        consumer = Consumer.new
        consumer.start(&block)
        consumer
      end

      class Consumer
        def start(&block)
          @running = true
          @thread = Thread.new do
            while @running
              responder = Responder.new
              block.call({text: rand(100).to_s}, responder)
            end
          end
        end

        def cancel
          @running = false
        end

        def join
          @thread.join
        end
      end

      class Responder
        def ack(*)
        end

        def nack(*)
        end
      end
    end
  end
end
