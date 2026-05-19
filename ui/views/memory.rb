require_relative "../charts/sparkline"

module RubyPulse
  module UI
    module Views
      class Memory
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Memory"
          @icon_name = "drive-harddisk-symbolic"

          build_charts
          @widget = build_widget

          listen_for_updates
        end

        private

        def build_charts
          @used_chart = Charts::Sparkline.new(color: [0.99, 0.45, 0.24, 0.8], fill_color: [0.99, 0.45, 0.24, 0.12])
          @used_chart.set_range(0, 100)
          @used_chart.height_request = 100

          @swap_chart = Charts::Sparkline.new(color: [0.62, 0.77, 0.26, 0.8], fill_color: [0.62, 0.77, 0.26, 0.12])
          @swap_chart.set_range(0, 100)
          @swap_chart.height_request = 80
        end

        def build_widget
          box = Gtk::Box.new(:vertical, 16)
          box.margin_start = 16
          box.margin_end = 16
          box.margin_top = 16
          box.margin_bottom = 16

          stats_row = Gtk::Box.new(:horizontal, 16)
          stats_row.homogeneous = true

          stats_row.append(stat_card("Total", @total_label = Gtk::Label.new("..."), "drive-harddisk-symbolic"))
          stats_row.append(stat_card("Used", @used_label = Gtk::Label.new("..."), "drive-harddisk-symbolic"))
          stats_row.append(stat_card("Available", @avail_label = Gtk::Label.new("..."), "drive-harddisk-symbolic"))

          box.append(stats_row)

          section_label = Gtk::Label.new
          section_label.markup = "<b>Usage Over Time</b>"
          section_label.halign = :start
          box.append(section_label)

          frame = Gtk::Frame.new
          frame.child = @used_chart
          box.append(frame)

          swap_row = Gtk::Box.new(:horizontal, 16)
          swap_row.homogeneous = true
          swap_row.append(stat_card("Swap Total", @swap_total_label = Gtk::Label.new("..."), "drive-harddisk-symbolic"))
          swap_row.append(stat_card("Swap Used", @swap_used_label = Gtk::Label.new("..."), "drive-harddisk-symbolic"))
          box.append(swap_row)

          section_label2 = Gtk::Label.new
          section_label2.markup = "<b>Swap Over Time</b>"
          section_label2.halign = :start
          box.append(section_label2)

          swap_frame = Gtk::Frame.new
          swap_frame.child = @swap_chart
          box.append(swap_frame)

          box
        end

        def stat_card(title, value_label, icon_name)
          frame = Gtk::Frame.new
          frame.add_css_class("overview-card")

          box = Gtk::Box.new(:vertical, 4)
          box.margin_start = 12
          box.margin_end = 12
          box.margin_top = 12
          box.margin_bottom = 12

          t = Gtk::Label.new
          t.markup = "<b>#{title}</b>"
          t.halign = :start
          box.append(t)

          value_label.add_css_class("overview-card-value")
          value_label.halign = :start
          box.append(value_label)

          frame.child = box
          frame
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :memory
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          metrics = data[:metrics] || {}
          total = metrics[:total] || 0
          free = metrics[:free] || 0
          available = metrics[:available] || 0
          swap_total = metrics[:swap_total] || 0
          swap_free = metrics[:swap_free] || 0

          used = total - available
          used_pct = total > 0 ? (used.to_f / total * 100).round(1) : 0.0
          swap_used = swap_total - swap_free
          swap_pct = swap_total > 0 ? (swap_used.to_f / swap_total * 100).round(1) : 0.0

          @total_label.text = format_memory(total)
          @used_label.text = "#{format_memory(used)} (#{used_pct}%)"
          @avail_label.text = format_memory(available)

          @swap_total_label.text = format_memory(swap_total)
          @swap_used_label.text = "#{format_memory(swap_used)} (#{swap_pct}%)"

          @used_chart.push(used_pct)
          @swap_chart.push(swap_pct)
        end

        def format_memory(kb)
          if kb >= 1_048_576
            format("%.1f GB", kb / 1_048_576.0)
          elsif kb >= 1024
            format("%.1f MB", kb / 1024.0)
          else
            format("%d KB", kb)
          end
        end
      end
    end
  end
end
