require_relative "../charts/sparkline"

module RubyPulse
  module UI
    module Views
      class Network
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Network"
          @icon_name = "network-wired-symbolic"
          @widget = build_widget

          @rx_charts = {}
          @tx_charts = {}

          listen_for_updates
        end

        private

        def build_widget
          box = Gtk::Box.new(:vertical, 16)
          box.margin_start = 16
          box.margin_end = 16
          box.margin_top = 16
          box.margin_bottom = 16

          @interface_list = Gtk::Box.new(:vertical, 12)
          box.append(@interface_list)

          box
        end

        def build_interface_row(name, data)
          row = Gtk::Frame.new
          row.add_css_class("overview-card")

          vbox = Gtk::Box.new(:vertical, 8)
          vbox.margin_start = 12
          vbox.margin_end = 12
          vbox.margin_top = 12
          vbox.margin_bottom = 12

          name_label = Gtk::Label.new
          name_label.markup = "<b>#{name}</b>"
          name_label.halign = :start
          vbox.append(name_label)

          stats = Gtk::Box.new(:horizontal, 16)
          stats.homogeneous = true

          rx_box = Gtk::Box.new(:vertical, 2)
          rx_label = Gtk::Label.new
          rx_label.markup = "<small>RX</small>"
          rx_label.halign = :start
          rx_box.append(rx_label)

          @rx_labels ||= {}
          @rx_labels[name] = Gtk::Label.new("0 B/s")
          @rx_labels[name].add_css_class("overview-card-value")
          @rx_labels[name].halign = :start
          rx_box.append(@rx_labels[name])
          stats.append(rx_box)

          tx_box = Gtk::Box.new(:vertical, 2)
          tx_label = Gtk::Label.new
          tx_label.markup = "<small>TX</small>"
          tx_label.halign = :start
          tx_box.append(tx_label)

          @tx_labels ||= {}
          @tx_labels[name] = Gtk::Label.new("0 B/s")
          @tx_labels[name].add_css_class("overview-card-value")
          @tx_labels[name].halign = :start
          tx_box.append(@tx_labels[name])
          stats.append(tx_box)

          total_box = Gtk::Box.new(:vertical, 2)
          total_label = Gtk::Label.new
          total_label.markup = "<small>Total RX</small>"
          total_label.halign = :start
          total_box.append(total_label)

          @total_rx_labels ||= {}
          @total_rx_labels[name] = Gtk::Label.new("0 GB")
          @total_rx_labels[name].opacity = 0.6
          @total_rx_labels[name].halign = :start
          total_box.append(@total_rx_labels[name])
          stats.append(total_box)

          vbox.append(stats)

          chart_box = Gtk::Box.new(:horizontal, 8)
          rx_chart = Charts::Sparkline.new(
            color: [0.31, 0.62, 0.87, 0.8],
            fill_color: [0.31, 0.62, 0.87, 0.12]
          )
          rx_chart.height_request = 40
          rx_chart.hexpand = true
          @rx_charts[name] = rx_chart

          tx_chart = Charts::Sparkline.new(
            color: [0.99, 0.45, 0.24, 0.8],
            fill_color: [0.99, 0.45, 0.24, 0.12]
          )
          tx_chart.height_request = 40
          tx_chart.hexpand = true
          @tx_charts[name] = tx_chart

          chart_box.append(rx_chart)
          chart_box.append(tx_chart)
          vbox.append(chart_box)

          row.child = vbox
          row
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :network
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          interfaces = data[:interfaces] || {}

          interfaces.each do |name, iface|
            unless @interface_rows&.key?(name)
              @interface_rows ||= {}
              row = build_interface_row(name, iface)
              @interface_rows[name] = row
              @interface_list.append(row)
            end

            @rx_labels[name].text = "#{format_bytes(iface[:rx_rate])}/s"
            @tx_labels[name].text = "#{format_bytes(iface[:tx_rate])}/s"
            @total_rx_labels[name].text = format_bytes_total(iface[:rx_bytes])

            @rx_charts[name].push(iface[:rx_rate])
            @tx_charts[name].push(iface[:tx_rate])
          end
        end

        def format_bytes(bytes)
          bytes = bytes.to_i
          if bytes >= 1_000_000_000
            format("%.1f GB", bytes / 1_000_000_000.0)
          elsif bytes >= 1_000_000
            format("%.1f MB", bytes / 1_000_000.0)
          elsif bytes >= 1_000
            format("%.1f KB", bytes / 1_000.0)
          else
            "#{bytes} B"
          end
        end

        def format_bytes_total(bytes)
          bytes = bytes.to_i
          if bytes >= 1_000_000_000
            format("%.2f GB", bytes / 1_000_000_000.0)
          elsif bytes >= 1_000_000
            format("%.1f MB", bytes / 1_000_000.0)
          else
            format("%.1f KB", bytes / 1_000.0)
          end
        end
      end
    end
  end
end
