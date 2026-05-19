module RubyPulse
  module Plugins
    class Base
      attr_reader :name, :version, :description

      def initialize(event_bus, scheduler, rules_engine)
        @event_bus = event_bus
        @scheduler = scheduler
        @rules = rules_engine
        @name = self.class.name
        @version = "0.1.0"
        @description = ""
      end

      def register_collector(klass, interval: 5)
        @scheduler.register(klass.new, interval: interval)
      end

      def register_rule(name, &block)
        @rules.rule(name, &block)
      end

      def on_activate
      end

      def on_deactivate
      end

      def log(msg)
        warn "[plugin:#{@name}] #{msg}"
      end
    end
  end
end
