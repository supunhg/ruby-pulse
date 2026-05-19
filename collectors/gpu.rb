module RubyPulse
  module Collectors
    class Gpu
      def collect
        metrics = if nvidia_available?
                    nvidia_metrics
                  else
                    drm_metrics
                  end

        { collector: :gpu, metrics: metrics, timestamp: Time.now }
      end

      private

      def nvidia_available?
        @has_nvidia = File.exist?("/usr/bin/nvidia-smi") if @has_nvidia.nil?
        @has_nvidia
      end

      def nvidia_metrics
        output = `nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name --format=csv,noheader,nounits 2>/dev/null`.strip
        return {} if output.empty?

        parts = output.split(", ")

        {
          vendor: "nvidia",
          name: parts[3] || "NVIDIA GPU",
          utilization: parts[0].to_f,
          memory_used_mb: (parts[1].to_f).round(0),
          memory_total_mb: (parts[2].to_f).round(0),
          temperature: parts[3..] ? parts[2..]&.first&.to_f : 0,
          available: true
        }
      rescue
        {}
      end

      def drm_metrics
        cards = Dir.glob("/sys/class/drm/card*/device")

        if cards.empty?
          return { available: false, vendor: "none" }
        end

        vendor = read_sysfs(cards.first, "vendor")
        temp = read_temp

        {
          vendor: vendor_name(vendor),
          temperature: temp,
          available: true
        }
      end

      def read_sysfs(path, file)
        File.read(File.join(path, file)).strip
      rescue
        "unknown"
      end

      def read_temp
        zones = Dir.glob("/sys/class/drm/card*/device/hwmon/hwmon*/temp1_input")
        return 0 if zones.empty?
        File.read(zones.first).to_i / 1000
      rescue
        0
      end

      def vendor_name(id)
        case id
        when /1002/i then "AMD"
        when /8086/i then "Intel"
        when /10de/i then "NVIDIA"
        else "Unknown"
        end
      end
    end
  end
end
