require_relative "models/process_entity"

module RubyPulse
  module Collectors
    class Process
      CLK_TCK = 100

      def initialize
        @prev_samples = {}
        @prev_total = nil
      end

      def collect
        processes = read_proc_tree
        total_cpu = read_total_cpu

        processes.each do |entry|
          prev = @prev_samples[entry[:pid]]
          if prev && total_cpu && @prev_total
            cpu_delta = entry[:jiffies] - prev[:jiffies]
            total_delta = total_cpu - @prev_total
            entry[:cpu] = total_delta > 0 ? ((cpu_delta.to_f / total_delta) * 100).round(1) : 0.0
          else
            entry[:cpu] = 0.0
          end
          @prev_samples[entry[:pid]] = { jiffies: entry[:jiffies] }
        end

        @prev_total = total_cpu

        {
          collector: :process,
          processes: processes.map { |p| entity_from(p) },
          total: processes.size,
          timestamp: Time.now
        }
      end

      private

      def read_proc_tree
        entries = Dir.glob("/proc/[0-9]*/stat").filter_map do |path|
          pid = File.basename(File.dirname(path)).to_i
          parse_process(pid, path)
        rescue Errno::EACCES, Errno::ENOENT
          nil
        end
        entries.sort_by! { |e| e[:pid] }
        entries
      end

      def parse_process(pid, stat_path)
        stat = File.read(stat_path)
        cmdline_path = File.dirname(stat_path) + "/cmdline"
        status_path = File.dirname(stat_path) + "/status"

        name = stat[/\(([^)]*)\)/, 1] || "?"
        fields = stat.split(" ")
        state = fields[2] || "?"
        ppid = fields[3].to_i
        utime = fields[13].to_f
        stime = fields[14].to_f
        jiffies = utime + stime
        threads = fields[19].to_i

        rss = read_rss(status_path)
        cmdline = File.read(cmdline_path).delete("\0").strip rescue name

        {
          pid: pid, name: name, ppid: ppid, state: state,
          cpu: 0.0, rss: rss, threads: threads,
          jiffies: jiffies, cmdline: cmdline
        }
      end

      def read_rss(status_path)
        File.readlines(status_path).each do |line|
          return line.split("\t").last.to_i if line.start_with?("VmRSS:")
        end
        0
      rescue
        0
      end

      def read_total_cpu
        line = File.read("/proc/stat")
        parts = line.lines.first.split
        return nil unless parts[0] == "cpu"
        parts[1..].map(&:to_i).sum
      rescue
        nil
      end

      def entity_from(entry)
        ProcessEntity.new(
          pid: entry[:pid],
          name: entry[:cmdline].empty? ? entry[:name] : entry[:cmdline],
          cpu: entry[:cpu],
          rss: entry[:rss],
          threads: entry[:threads],
          state: entry[:state],
          ppid: entry[:ppid]
        )
      end
    end
  end
end
