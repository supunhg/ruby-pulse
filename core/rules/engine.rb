module RubyPulse
  module Rules
    class Rule
      attr_reader :name, :severity

      def initialize(name)
        @name = name
        @severity = :info
        @cooldown = 30
        @check_block = nil
        @message_block = nil
        @last_fired_at = Time.at(0)
        @was_active = false
      end

      def severity(s = nil)
        return @severity unless s
        @severity = s
      end

      def every(seconds)
        @cooldown = seconds
      end

      def check(&block)
        @check_block = block
      end

      def message(&block)
        @message_block = block
      end

      def evaluate(state, now)
        passes = @check_block ? @check_block.call(state) : false

        if passes && (now - @last_fired_at) >= @cooldown
          @last_fired_at = now
          @was_active = true
          true
        elsif !passes && @was_active
          @was_active = false
          :resolved
        else
          false
        end
      end

      def build_diagnostic(state)
        msg = @message_block ? @message_block.call(state) : @name
        RubyPulse::Diagnostics::Diagnostic.new(@name, @severity, msg)
      end
    end

    class Engine
      def initialize(event_bus, state)
        @event_bus = event_bus
        @state = state
        @rules = []
      end

      def rule(name, &block)
        r = Rule.new(name)
        r.instance_eval(&block)
        @rules << r
        r
      end

      def start
        @event_bus.on(:collector_update) { |_data| evaluate }
      end

      private

      def evaluate
        now = Time.now
        @rules.each do |rule|
          result = rule.evaluate(@state, now)
          case result
          when true
            diag = rule.build_diagnostic(@state)
            @event_bus.emit(:diagnostic_fired, diag)
          when :resolved
            @event_bus.emit(:diagnostic_resolved, rule.name)
          end
        end
      end
    end
  end
end
