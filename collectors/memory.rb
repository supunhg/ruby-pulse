module RubyPulse
  module Collectors
    class Memory
      def collect
        { collector: :memory, metrics: parse_meminfo, timestamp: Time.now }
      end

      private

      def parse_meminfo
        lines = File.readlines("/proc/meminfo")
        {
          total: parse_line(lines, "MemTotal"),
          free: parse_line(lines, "MemFree"),
          available: parse_line(lines, "MemAvailable"),
          swap_total: parse_line(lines, "SwapTotal"),
          swap_free: parse_line(lines, "SwapFree")
        }
      rescue Errno::ENOENT
        {}
      end

      def parse_line(lines, key)
        line = lines.find { |l| l.start_with?("#{key}:") }
        (line&.split || [])[1]&.to_i || 0
      end
    end
  end
end
