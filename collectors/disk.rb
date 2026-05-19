module RubyPulse
  module Collectors
    class Disk
      def initialize
        @prev_time = Time.now
        @prev_stats = {}
      end

      def collect
        now = Time.now
        io_data = collect_io(now)
        fs_data = collect_filesystems

        {
          collector: :disk,
          io: io_data,
          filesystems: fs_data,
          timestamp: now
        }
      rescue => e
        { collector: :disk, io: {}, filesystems: [], error: e.message }
      end

      private

      def collect_io(now)
        stats = {}
        elapsed = [(now - @prev_time).to_f, 1.0].max

        File.readlines("/proc/diskstats").each do |line|
          fields = line.split
          next if fields.size < 14
          name = fields[2]
          next if name.start_with?("loop", "ram", "zram")

          reads = fields[3].to_i
          read_merged = fields[4].to_i
          read_sectors = fields[5].to_i
          read_ms = fields[6].to_i
          writes = fields[7].to_i
          write_merged = fields[8].to_i
          write_sectors = fields[9].to_i
          write_ms = fields[10].to_i

          prev = @prev_stats[name]

          read_bps = 0.0
          write_bps = 0.0
          read_iops = 0.0
          write_iops = 0.0

          if prev
            read_bps = ((read_sectors - prev[:read_sectors]) * 512.0 / elapsed)
            write_bps = ((write_sectors - prev[:write_sectors]) * 512.0 / elapsed)
          end

          @prev_stats[name] = {
            read_sectors: read_sectors,
            write_sectors: write_sectors,
            reads: reads,
            writes: writes
          }

          stats[name] = {
            name: name,
            read_bytes_s: read_bps,
            write_bytes_s: write_bps,
            read_total_gb: read_sectors * 512.0 / (1024**3),
            write_total_gb: write_sectors * 512.0 / (1024**3)
          }
        end

        @prev_time = now
        stats
      rescue Errno::ENOENT
        {}
      end

      def collect_filesystems
        results = []

        IO.popen(["df", "-B1"], &:read).lines.drop(1).each do |line|
          fields = line.split
          next if fields.size < 6
          device, total, used, available, pct, mount = fields

          next if device.start_with?("tmpfs", "devtmpfs", "overlay")
          next if mount == "/dev"

          results << {
            device: device,
            mount: mount,
            total_bytes: total.to_i,
            used_bytes: used.to_i,
            available_bytes: available.to_i,
            percent_used: pct.to_f
          }
        end

        results
      rescue => e
        []
      end
    end
  end
end