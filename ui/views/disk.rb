require_relative "../charts/sparkline"

module RubyPulse
  module UI
    module Views
      class Disk
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Disk"
          @icon_name = "drive-harddisk-symbolic"

          @io_charts = {}
          @fs_bars = []

          @widget = build_widget
          listen_for_updates
        end

        private

        def build_widget
          box = Gtk::Box.new(:vertical, 16)
          box.margin_start = 16
          box.margin_end = 16
          box.margin_top = 16
          box.margin_bottom = 16

          header = Gtk::Box.new(:horizontal, 6)
          title = Gtk::Label.new
          title.markup = "<span size='large'><b>Disk Activity</b></span>"
          title.halign = :start
          title.hexpand = true
          header.append(title)

          @io_label = Gtk::Label.new
          @io_label.halign = :end
          header.append(@io_label)
          box.append(header)

          @io_box = Gtk::Box.new(:vertical, 8)
          @io_box.vexpand = true
          box.append(@io_box)

          sep = Gtk::Separator.new(:horizontal)
          box.append(sep)

          fs_header = Gtk::Label.new
          fs_header.markup = "<span size='large'><b>Filesystems</b></span>"
          fs_header.halign = :start
          box.append(fs_header)

          @fs_box = Gtk::Box.new(:vertical, 8)
          @fs_box.vexpand = true
          box.append(@fs_box)

          box
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :disk
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          io_data = data[:io] || {}
          fs_data = data[:filesystems] || []

          update_io(io_data)
          update_filesystems(fs_data)
        end

        def update_io(io_data)
          return if io_data.empty?

          total_read = 0.0
          total_write = 0.0

          io_data.each do |name, stats|
            total_read += stats[:read_bytes_s] || 0
            total_write += stats[:write_bytes_s] || 0
            ensure_io_chart(name, stats)
            @io_charts[name]&.first&.push(stats[:read_bytes_s] || 0) rescue nil
            @io_charts[name]&.last&.push(stats[:write_bytes_s] || 0) rescue nil
          end

          @io_label.text = "r #{format_rate(total_read)}  w #{format_rate(total_write)}"
        end

        def ensure_io_chart(name, stats)
          return if @io_charts.key?(name)

          row = Gtk::Box.new(:horizontal, 12)
          row.margin_bottom = 8

          label = Gtk::Label.new(name)
          label.halign = :start
          label.width_chars = 10
          row.append(label)

          read_chart = Charts::Sparkline.new(
            color: [0.31, 0.62, 0.87, 0.8],
            fill_color: [0.31, 0.62, 0.87, 0.12]
          )
          read_chart.set_range(0, 100)
          read_chart.height_request = 60
          read_chart.hexpand = true
          row.append(read_chart)

          write_chart = Charts::Sparkline.new(
            color: [0.62, 0.77, 0.26, 0.8],
            fill_color: [0.62, 0.77, 0.26, 0.12]
          )
          write_chart.set_range(0, 100)
          write_chart.height_request = 60
          write_chart.hexpand = true
          row.append(write_chart)

          @io_box.append(row)
          @io_charts[name] = [read_chart, write_chart]
        end

        def update_filesystems(fs_data)
          @fs_box.children.each { |c| @fs_box.remove(c) } rescue nil

          fs_data.each do |fs|
            bar_row = Gtk::Box.new(:horizontal, 8)
            bar_row.margin_top = 4
            bar_row.margin_bottom = 4

            label = Gtk::Label.new(fs[:mount] || fs[:device] || "?")
            label.halign = :start
            label.width_chars = 18
            label.ellipsize = :end
            bar_row.append(label)

            pct = (fs[:percent_used] || 0).to_f
            total_str = format_bytes(fs[:total_bytes] || 0)
            used_str = format_bytes(fs[:used_bytes] || 0)
            avail_str = format_bytes(fs[:available_bytes] || 0)

            info_label = Gtk::Label.new("#{used_str} / #{total_str}")
            info_label.halign = :start
            info_label.hexpand = true
            bar_row.append(info_label)

            pct_label = Gtk::Label.new("#{pct.round(0)}%")
            pct_label.halign = :end
            bar_row.append(pct_label)

            @fs_box.append(bar_row)

            progress = Gtk::LevelBar.new
            progress.value = pct / 100.0
            progress.hexpand = true
            progress.margin_bottom = 8
            @fs_box.append(progress)
          end
        end

        def format_rate(bytes_per_sec)
          return "0 B/s" if bytes_per_sec.nil? || bytes_per_sec < 1024
          return format("%.1f KB/s", bytes_per_sec / 1024) if bytes_per_sec < 1024 * 1024
          return format("%.1f MB/s", bytes_per_sec / (1024 * 1024)) if bytes_per_sec < 1024 * 1024 * 1024
          format("%.2f GB/s", bytes_per_sec / (1024**3))
        end

        def format_bytes(bytes)
          return "0 B" if bytes.nil? || bytes == 0
          return format("%.1f KB", bytes / 1024.0) if bytes < 1024 * 1024
          return format("%.1f MB", bytes / (1024 * 1024)) if bytes < 1024 * 1024 * 1024
          format("%.1f GB", bytes / (1024.0**3))
        end
      end
    end
  end
end