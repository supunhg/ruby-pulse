module RubyPulse
  module Collectors
    class Thermal
      def collect
        { collector: :thermal, zones: read_zones, timestamp: Time.now }
      end

      private

      def read_zones
        Dir.glob("/sys/class/thermal/thermal_zone*").filter_map do |path|
          type = read_file(File.join(path, "type"))
          temp = read_file(File.join(path, "temp"))
          next unless type && temp

          {
            type: type.strip,
            temp_c: (temp.strip.to_i / 1000.0).round(1)
          }
        end
      rescue Errno::ENOENT
        []
      end

      def read_file(path)
        File.read(path)
      rescue Errno::ENOENT, Errno::EACCES
        nil
      end
    end
  end
end
