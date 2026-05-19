module RubyPulse
  module Notifications
    class Handler
      def initialize(event_bus)
        @event_bus = event_bus
      end

      def start
        @event_bus.on(:diagnostic) { |diag| notify(diag) }
      end

      private

      def notify(diagnostic)
        # Phase 3: integrate libnotify or in-app banner
      end
    end
  end
end
