require_relative "diagnostic"

module RubyPulse
  module Diagnostics
    class Engine
      attr_reader :actives, :history

      def initialize(event_bus, state)
        @event_bus = event_bus
        @state = state
        @actives = []
        @history = []
      end

      def start
        @event_bus.on(:diagnostic_fired) { |diag| activate(diag) }
        @event_bus.on(:diagnostic_resolved) { |rule_name| resolve(rule_name) }
      end

      def activate(diag)
        existing = @actives.find { |d| d.rule_name == diag.rule_name }
        return if existing

        @actives << diag
        @history << diag
        @event_bus.emit(:diagnostics_count, @actives.size)
        @event_bus.emit(:diagnostic, diag)
      end

      def resolve(rule_name)
        removed = @actives.reject! { |d| d.rule_name == rule_name }
        if removed
          @event_bus.emit(:diagnostics_count, @actives.size)
          @event_bus.emit(:diagnostic_resolved_ui, rule_name)
        end
      end
    end
  end
end
