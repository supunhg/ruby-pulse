module RubyPulse
  module Events
    class Bus
      def initialize
        @listeners = Hash.new { |h, k| h[k] = [] }
        @mutex = Mutex.new
      end

      def on(event, &block)
        @mutex.synchronize { @listeners[event] << block }
      end

      def emit(event, payload = nil)
        @mutex.synchronize do
          @listeners[event].each { |listener| listener.call(payload) }
        end
      end

      def start; end

      def stop; end
    end
  end
end
