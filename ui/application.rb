require_relative "application_window"

module RubyPulse
  module UI
    class Application
      attr_reader :app

      def initialize(event_bus, state, notifications_handler)
        @event_bus = event_bus
        @state = state
        @notifications = notifications_handler
        @app = Adw::Application.new(
          "io.github.supunhg.ruby-pulse",
          Gio::ApplicationFlags::FLAGS_NONE
        )
        @app.signal_connect :activate do |application|
          @notifications.bind_app(application)
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
