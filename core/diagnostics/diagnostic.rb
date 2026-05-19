module RubyPulse
  module Diagnostics
    class Diagnostic
      attr_reader :rule_name, :severity, :message, :timestamp, :data

      def initialize(rule_name, severity, message, data = {})
        @rule_name = rule_name
        @severity = severity
        @message = message
        @data = data
        @timestamp = Time.now
      end
    end
  end
end
