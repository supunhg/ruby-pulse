require_relative "../charts/sparkline"

module RubyPulse
  module UI
    module Views
      class Gpu
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "GPU"
          @icon_name = "video-display-symbolic"
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

          @status_label = Gtk::Label.new
          @status_label.markup = "<span size='xx-large'>Scanning...</span>"
          @status_label.halign = :start
          box.append(@status_label)

          stats_row = Gtk::Box.new(:horizontal, 16)
          stats_row.homogeneous = true

          @util_label = Gtk::Label.new("...")
          @mem_label = Gtk::Label.new("...")
          @temp_label = Gtk::Label.new("...")

          stats_row.append(stat_card("Utilization", @util_label, "video-display-symbolic"))
          stats_row.append(stat_card("Memory", @mem_label, "drive-harddisk-symbolic"))
          stats_row.append(stat_card("Temperature", @temp_label, "weather-clear-symbolic"))

          box.append(stats_row)

          @chart = Charts::Sparkline.new(
            color: [0.62, 0.77, 0.26, 0.8],
            fill_color: [0.62, 0.77, 0.26, 0.12]
          )
          @chart.set_range(0, 100)
          @chart.height_request = 100
          frame = Gtk::Frame.new
          frame.child = @chart
          box.append(frame)

          box
        end

        def stat_card(title, value_label, icon_name)
          frame = Gtk::Frame.new
          frame.add_css_class("overview-card")
          b = Gtk::Box.new(:vertical, 4)
          b.margin_start = 12
          b.margin_end = 12
          b.margin_top = 12
          b.margin_bottom = 12
          t = Gtk::Label.new
          t.markup = "<b>#{title}</b>"
          t.halign = :start
          b.append(t)
          value_label.add_css_class("overview-card-value")
          value_label.halign = :start
          b.append(value_label)
          frame.child = b
          frame
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :gpu
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          metrics = data[:metrics] || {}

          unless metrics[:available]
            @status_label.markup = "<span size='large'>No GPU Detected</span>"
            @util_label.text = "N/A"
            @mem_label.text = "N/A"
            @temp_label.text = "N/A"
            return
          end

          @status_label.markup = "<span size='xx-large'>#{metrics[:name] || 'GPU'}</span>"

          util = metrics[:utilization] || 0
          @util_label.text = "#{util}%"
          @chart.push(util)

          if metrics[:memory_total_mb]&.> 0
            used = metrics[:memory_used_mb] || 0
            total = metrics[:memory_total_mb]
            @mem_label.text = "#{used} / #{total} MB"
          else
            @mem_label.text = "N/A"
          end

          temp = (metrics[:temperature] || metrics[:temp_c]).to_f
          @temp_label.text = temp > 0 ? "#{temp}°C" : "N/A"
        end
      end
    end
  end
end
