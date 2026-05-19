module RubyPulse
  module Collectors
    class Process
      def collect
        { collector: :process, processes: read_proc_entries, timestamp: Time.now }
      end

      private

      def read_proc_entries
        Dir.glob("/proc/[0-9]*/status").map do |path|
          pid = File.basename(File.dirname(path)).to_i
          { pid: pid, name: read_name(path) }
        end
      rescue Errno::EACCES, Errno::ENOENT
        []
      end

      def read_name(path)
        File.readlines(path).first&.split("\t")&.last&.strip
      rescue
        "unknown"
      end
    end
  end
end
