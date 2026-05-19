module RubyPulse
  module Collectors
    class Network
      def initialize
        @prev = {}
      end

      def collect
        current = read_interfaces
        rates = compute_rates(current)
        @prev = current

        { collector: :network, interfaces: rates, timestamp: Time.now }
      end

      private

      def read_interfaces
        lines = File.readlines("/proc/net/dev")
        interfaces = {}

        lines.each do |line|
          next unless line.include?(":")
          name, rest = line.split(":")
          stats = rest.split.map(&:to_i)

          interfaces[name.strip] = {
            rx_bytes: stats[0],
            rx_packets: stats[1],
            tx_bytes: stats[8],
            tx_packets: stats[9]
          }
        end

        interfaces
      rescue Errno::ENOENT
        {}
      end

      def compute_rates(current)
        result = {}

        current.each do |name, cur|
          prev = @prev[name]
          if prev
            delta_t = 2.0
            result[name] = {
              rx_bytes: cur[:rx_bytes],
              tx_bytes: cur[:tx_bytes],
              rx_rate: ((cur[:rx_bytes] - prev[:rx_bytes]) / delta_t).round(0).to_i,
              tx_rate: ((cur[:tx_bytes] - prev[:tx_bytes]) / delta_t).round(0).to_i
            }
          else
            result[name] = {
              rx_bytes: cur[:rx_bytes],
              tx_bytes: cur[:tx_bytes],
              rx_rate: 0,
              tx_rate: 0
            }
          end
        end

        result
      end
    end
  end
end
