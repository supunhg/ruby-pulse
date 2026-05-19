require_relative "../charts/sparkline"

module RubyPulse
  module UI
    module Views
      class Cpu
        attr_reader :title, :icon_name, :widget

        CORE_COLORS = [
          [0.31, 0.62, 0.87, 0.8],  [0.99, 0.45, 0.24, 0.8],
          [0.62, 0.77, 0.26, 0.8],  [0.80, 0.38, 0.68, 0.8],
          [0.96, 0.73, 0.20, 0.8],  [0.35, 0.82, 0.75, 0.8],
          [0.90, 0.38, 0.34, 0.8],  [0.53, 0.46, 0.87, 0.8],
          [0.20, 0.70, 0.40, 0.8],  [0.95, 0.58, 0.22, 0.8],
          [0.42, 0.52, 0.68, 0.8],  [0.75, 0.42, 0.26, 0.8],
          [0.38, 0.70, 0.56, 0.8],  [0.84, 0.48, 0.48, 0.8],
          [0.44, 0.56, 0.74, 0.8],  [0.68, 0.52, 0.32, 0.8]
        ].freeze

        FILL_COLOR = [0.31, 0.62, 0.87, 0.12].freeze

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "CPU"
          @icon_name = "processor-symbolic"
          @core_charts = {}

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

          @total_label = Gtk::Label.new
          @total_label.markup = "<span size='xx-large'>0.0%</span>"
          @total_label.halign = :start
          box.append(@total_label)

          @total_chart = Charts::Sparkline.new(color: CORE_COLORS[0], fill_color: FILL_COLOR)
          @total_chart.set_range(0, 100)
          @total_chart.height_request = 120

          total_frame = Gtk::Frame.new
          total_frame.child = @total_chart
          box.append(total_frame)

          section = Gtk::Label.new
          section.markup = "<b>Per-Core Usage</b>"
          section.halign = :start
          box.append(section)

          @core_grid = Gtk::Grid.new
          @core_grid.column_spacing = 12
          @core_grid.row_spacing = 12
          @core_grid.margin_top = 4
          box.append(@core_grid)

          box
        end

        def ensure_core_charts(num_cores)
          return if num_cores <= @core_charts.size

          @core_grid.each { |_w| @core_grid.remove(_w) } if @core_charts.any?

          num_cores.times do |i|
            color = CORE_COLORS[i % CORE_COLORS.size]
            chart = Charts::Sparkline.new(color: color, fill_color: FILL_COLOR)
            chart.set_range(0, 100)
            chart.height_request = 60
            @core_charts[i] = chart

            vbox = Gtk::Box.new(:vertical, 4)
            label = Gtk::Label.new
            label.markup = format("<small>Core %d</small>", i)
            label.halign = :center
            vbox.append(label)
            vbox.append(chart)

            col = i % 4
            row = i / 4
            @core_grid.attach(vbox, col, row, 1, 1)
          end
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :cpu
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update(data)
              false
            end
          end
        end

        def update(data)
          total = data[:total] || 0.0
          cores = data[:cores] || {}

          @total_label.markup = "<span size='xx-large'>#{total}%</span>"
          @total_chart.push(total)

          ensure_core_charts(cores.size)

          cores.each do |id, pct|
            @core_charts[id]&.push(pct)
          end
        end
      end
    end
  end
end
