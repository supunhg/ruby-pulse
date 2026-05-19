module RubyPulse
  module Diagnostics
    class Engine
      def initialize(event_bus, state)
        @event_bus = event_bus
        @state = state
      end

      def start
        @event_bus.on(:diagnostic_trigger) { |diag| emit(diag) }
      end

      def emit(diagnostic)
        @event_bus.emit(:diagnostic, diagnostic)
      end
    end
  end
end
