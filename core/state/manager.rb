module RubyPulse
  module State
    class Manager
      attr_reader :snapshots

      def initialize(event_bus)
        @event_bus = event_bus
        @snapshots = {}
        @mutex = Mutex.new

        @event_bus.on(:collector_update) { |data| update(data) }
      end

      def update(data)
        @mutex.synchronize do
          @snapshots[data[:collector]] = data
        end
      end

      def latest(collector)
        @mutex.synchronize { @snapshots[collector] }
      end

      def all
        @mutex.synchronize { @snapshots.dup }
      end
    end
  end
end
