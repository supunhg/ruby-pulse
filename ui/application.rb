require_relative "application_window"

module RubyPulse
  module UI
    class Application
      def initialize(event_bus, state)
        @event_bus = event_bus
        @state = state
        @app = Adw::Application.new(
          "io.github.supunhg.ruby-pulse",
          Gio::ApplicationFlags::FLAGS_NONE
        )
        @app.signal_connect :activate do |application|
          @window = ApplicationWindow.new(application, @event_bus, @state)
          @window.present
        end
      end

      def run
        @app.run
      end
    end
  end
end
