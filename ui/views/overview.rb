module RubyPulse
  module UI
    module Views
      class Overview
        attr_reader :title, :icon_name, :widget

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Overview"
          @icon_name = "computer-symbolic"
          @widget = build_widget

          listen_for_updates
        end

        private

        def build_widget
          @box = Gtk::Box.new(:vertical, 16)
          @box.margin_start = 24
          @box.margin_end = 24
          @box.margin_top = 24
          @box.margin_bottom = 24

          header = Gtk::Label.new
          header.markup = "<span size='xx-large'>Ruby Pulse</span>"
          header.halign = :start
          @box.append(header)

          subtitle = Gtk::Label.new
          subtitle.markup = "<span size='large' alpha='60%'>System intelligence for Linux desktops</span>"
          subtitle.halign = :start
          @box.append(subtitle)

          @cards = Gtk::Box.new(:horizontal, 12)
          @cards.homogeneous = true
          @cards.margin_top = 12
          @box.append(@cards)

          @process_value = Gtk::Label.new("...")
          @memory_value = Gtk::Label.new("...")
          @diag_value = Gtk::Label.new("0")
          @diag_value.add_css_class("overview-card-value")
          @diag_value.halign = :start
          @temp_value = Gtk::Label.new("...")
          @temp_value.add_css_class("overview-card-value")
          @temp_value.halign = :start
          @container_value = Gtk::Label.new("...")
          @container_value.add_css_class("overview-card-value")
          @container_value.halign = :start

          @process_card = build_card("Processes", @process_value, "utilities-system-monitor-symbolic")
          @memory_card = build_card("Memory", @memory_value, "drive-harddisk-symbolic")
          @diagnostics_card = build_card("Issues", @diag_value, "emblem-important-symbolic")
          @temp_card = build_card("Temperature", @temp_value, "weather-clear-symbolic")
          @container_card = build_card("Containers", @container_value, "computer-symbolic")

          rebuild_cards
          @box
        end

        def build_card(title, value_label, icon_name)
          frame = Gtk::Frame.new
          frame.add_css_class("overview-card")

          box = Gtk::Box.new(:vertical, 6)
          box.margin_start = 16
          box.margin_end = 16
          box.margin_top = 16
          box.margin_bottom = 16

          icon = Gtk::Image.new
          icon.icon_name = icon_name
          icon.pixel_size = 24
          icon.halign = :start
          box.append(icon)

          label_title = Gtk::Label.new
          label_title.markup = "<b>#{title}</b>"
          label_title.halign = :start
          box.append(label_title)

          value_label.add_css_class("overview-card-value")
          value_label.halign = :start
          box.append(value_label)

          frame.child = box
          frame
        end

        def rebuild_cards
          @cards.append(@process_card)
          @cards.append(@memory_card)
          @cards.append(@diagnostics_card)
          @cards.append(@temp_card)
          @cards.append(@container_card)
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update_cards(data)
              false
            end
          end

          @event_bus.on :diagnostics_count do |count|
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              @diag_value.text = count.to_s
              false
            end
          end
        end

        def update_cards(data)
          case data[:collector]
          when :process
            total = data[:total] || 0
            @process_value.text = total.to_s
          when :memory
            metrics = data[:metrics] || {}
            total = metrics[:total] || 0
            available = metrics[:available] || 0
            used = total - available
            used_gb = used / 1_048_576.0
            @memory_value.text = format("%.1f GB", used_gb)
          when :thermal
            zones = data[:zones] || []
            cpu_zones = zones.select { |z| z[:type].include?("cpu") || z[:type].include?("x86") }
            if cpu_zones.any?
              max_temp = cpu_zones.map { |z| z[:temp_c] }.max
              @temp_value.text = "#{max_temp}°C"
            elsif zones.any?
              @temp_value.text = "#{zones.first[:temp_c]}°C"
            end
          when :container
            containers = data[:containers] || []
            running = containers.count { |c| c[:running] }
            @container_value.text = running.to_s
          end
        end
      end
    end
  end
end
