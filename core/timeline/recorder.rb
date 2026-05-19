module RubyPulse
  module Timeline
    class Recorder
      def initialize(event_bus)
        @event_bus = event_bus
        @events = []
      end

      def start
        @event_bus.on(:diagnostic) { |diag| record(:diagnostic, diag) }
        @event_bus.on(:collector_update) { |data| record(:telemetry, data) }
      end

      private

      def record(type, payload)
        @events << { type: type, payload: payload, timestamp: Time.now }
      end
    end
  end
end
