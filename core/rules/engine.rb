module RubyPulse
  module Rules
    class Engine
      def initialize(event_bus, state)
        @event_bus = event_bus
        @state = state
        @rules = []
      end

      def define(&block)
        instance_eval(&block)
      end

      def rule(name, &block)
        @rules << Rule.new(name, block)
      end

      def start
        @event_bus.on(:collector_update) { |data| evaluate(data) }
      end

      private

      def evaluate(data)
        @rules.each { |rule| rule.check(data, @event_bus) }
      end
    end

    class Rule
      def initialize(name, block)
        @name = name
        @block = block
      end

      def check(data, event_bus)
        instance_exec(data, &@block)
      rescue => e
        # Log rule error
      end
    end
  end
end
