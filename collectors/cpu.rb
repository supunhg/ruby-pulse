module RubyPulse
  module Collectors
    class Cpu
      def initialize
        @prev = nil
      end

      def collect
        current = read_stat
        percents = compute_percents(current)
        @prev = current

        {
          collector: :cpu,
          total: percents[:total],
          cores: percents[:cores],
          timestamp: Time.now
        }
      end

      private

      def read_stat
        lines = File.readlines("/proc/stat")
        cores = {}
        total = nil

        lines.each do |line|
          case line
          when /\Acpu\s/
            total = parse_line(line)
          when /\Acpu(\d+)\s/
            cores[$1.to_i] = parse_line(line)
          end
        end

        { total: total, cores: cores }
      rescue Errno::ENOENT
        { total: nil, cores: {} }
      end

      def parse_line(line)
        parts = line.split
        {
          user: parts[1].to_i,
          nice: parts[2].to_i,
          system: parts[3].to_i,
          idle: parts[4].to_i,
          iowait: parts[5].to_i,
          irq: parts[6].to_i,
          softirq: parts[7].to_i,
          steal: parts[8].to_i
        }
      end

      def compute_percents(current)
        return { total: 0.0, cores: {} } unless @prev && current[:total]

        prev_total = @prev[:total]
        total_delta = delta(prev_total, current[:total], :all)
        total_pct = total_delta > 0 ? (1.0 - delta(prev_total, current[:total], :idle).to_f / total_delta) * 100 : 0.0

        core_pcts = {}
        current[:cores].each do |id, cur|
          prev = @prev[:cores][id]
          next unless prev
          cd = delta(prev, cur, :all)
          core_pcts[id] = cd > 0 ? (1.0 - delta(prev, cur, :idle).to_f / cd) * 100 : 0.0
        end

        { total: total_pct.round(1), cores: core_pcts }
      end

      def delta(prev, cur, type)
        if type == :all
          cur.values.sum - prev.values.sum
        else
          (cur[type] || 0) - (prev[type] || 0)
        end
      end
    end
  end
end
