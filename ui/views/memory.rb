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
          @widget = build_widget
        end

        private

        def build_widget
          box = Gtk::Box.new(:vertical, 12)
          box.margin_start = 12
          box.margin_end = 12
          box.margin_top = 12
          box.margin_bottom = 12

          frame = Gtk::Frame.new("Memory Usage")
          placeholder = Gtk::Label.new("Memory charts will appear here (Phase 2)")
          placeholder.margin_top = 24
          placeholder.margin_bottom = 24
          frame.child = placeholder
          box.append(frame)

          box
        end
      end
    end
  end
end
