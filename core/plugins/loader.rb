module RubyPulse
  module Plugins
    class Loader
      def initialize(event_bus)
        @event_bus = event_bus
        @plugins = []
      end

      def load(path)
        # Phase 7: isolate plugin loading
      end
    end
  end
end
