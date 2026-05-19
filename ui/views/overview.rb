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
        end

        private

        def build_widget
          box = Gtk::Box.new(:vertical, 12)
          box.margin_start = 24
          box.margin_end = 24
          box.margin_top = 24
          box.margin_bottom = 24

          label = Gtk::Label.new
          label.markup = "<span size='xx-large'>Welcome to Ruby Pulse</span>"
          box.append(label)

          subtitle = Gtk::Label.new
          subtitle.markup = "<span size='large' alpha='60%'>System intelligence for Linux desktops</span>"
          box.append(subtitle)

          box
        end
      end
    end
  end
end
