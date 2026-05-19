module RubyPulse
  module Scheduler
    class Runner
      def initialize(event_bus)
        @event_bus = event_bus
        @collectors = []
        @threads = []
      end

      def register(collector, interval: 2)
        @collectors << { collector: collector, interval: interval }
      end

      def start
        @collectors.each do |entry|
          @threads << Thread.new do
            loop do
              sleep entry[:interval]
              data = entry[:collector].collect
              @event_bus.emit(:collector_update, data)
            end
          end
        end
      end

      def stop
        @threads.each(&:kill)
      end
    end
  end
end
