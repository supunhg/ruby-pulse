module RubyPulse
  module UI
    module Views
      class Power
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Power"
          @icon_name = "battery-good-symbolic"
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

          @charge_label = Gtk::Label.new("...")
          @power_label = Gtk::Label.new("...")
          @health_label = Gtk::Label.new("...")

          stats_row.append(stat_card("Charge", @charge_label, "battery-good-symbolic"))
          stats_row.append(stat_card("Power Draw", @power_label, "emblem-system-symbolic"))
          stats_row.append(stat_card("Status", @health_label, "weather-clear-symbolic"))

          box.append(stats_row)
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
            next unless data[:collector] == :power
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          battery = data[:battery] || {}

          unless battery[:present]
            @status_label.markup = "<span size='large'>No Battery Detected</span>"
            @charge_label.text = "N/A"
            @power_label.text = "N/A"
            @health_label.text = "Desktop"
            return
          end

          pct = battery[:charge_pct] || 0
          status = battery[:status] || "Unknown"
          power = battery[:power_now_mw]

          @status_label.markup = "<span size='xx-large'>#{pct}%</span>"

          @charge_label.text = pct.to_s
          @power_label.text = power ? format_power(power.to_f / 1_000_000) : "N/A"

          @health_label.text = case status.downcase
                               when "charging" then "⚡ Charging"
                               when "discharging" then "🔋 Discharging"
                               when "full" then "✅ Full"
                               else status
                               end
        end

        def format_power(watts)
          "#{format('%.2f', watts)} W"
        end
      end
    end
  end
end
