require "json"
require_relative "../../storage/database"

module RubyPulse
  module Timeline
    class Recorder
      TELEMETRY_SAMPLE_INTERVAL = 5
      SAMPLE_COLLECTORS = %i[process memory cpu].freeze

      def initialize(event_bus)
        @event_bus = event_bus
        @db = nil
        @sample_count = 0
      end

      def start
        db_path = File.expand_path("../../data/timeline.db", __dir__)
        FileUtils.mkdir_p(File.dirname(db_path))
        @db = Storage::Database.new(db_path)
        @running = true

        record_system("app_start")

        @event_bus.on(:diagnostic) { |diag| record_diagnostic(diag) }
        @event_bus.on(:collector_update) { |data| try_record_telemetry(data) }
      end

      def stop
        @running = false
        record_system("app_stop")
        @db&.close
      end

      private

      def record_diagnostic(diag)
        @db&.insert_event(:diagnostic, {
          rule: diag.rule_name,
          severity: diag.severity,
          message: diag.message,
          timestamp: diag.timestamp.iso8601
        })
      end

      def try_record_telemetry(data)
        return unless SAMPLE_COLLECTORS.include?(data[:collector])
        @sample_count += 1
        return unless @sample_count % TELEMETRY_SAMPLE_INTERVAL == 0

        @db&.insert_event(:telemetry, {
          collector: data[:collector],
          metrics: data[:metrics] || data.except(:collector, :timestamp),
          timestamp: Time.now.iso8601
        })
      end

      def record_system(event)
        @db&.insert_event(:system, { event: event })
      end
    end
  end
end
