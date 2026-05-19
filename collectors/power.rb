module RubyPulse
  module Collectors
    class Power
      BATTERY_PATHS = [
        "/sys/class/power_supply/BAT0",
        "/sys/class/power_supply/BAT1"
      ].freeze

      def collect
        { collector: :power, battery: read_battery, timestamp: Time.now }
      end

      private

      def read_battery
        path = BATTERY_PATHS.find { |p| Dir.exist?(p) }
        return { present: false } unless path

        status = read_sysfs(path, "status")
        capacity = read_sysfs(path, "capacity")
        energy_now = read_sysfs(path, "energy_now")
        energy_full = read_sysfs(path, "energy_full")
        power_now = read_sysfs(path, "power_now")

        {
          present: true,
          status: status,
          capacity: capacity,
          energy_now_mwh: energy_now,
          energy_full_mwh: energy_full,
          power_now_mw: power_now,
          charge_pct: capacity.to_i
        }
      rescue Errno::ENOENT
        { present: false }
      end

      def read_sysfs(path, file)
        File.read(File.join(path, file)).strip
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
