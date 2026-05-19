module RubyPulse
  module Notifications
    class Handler
      SEVERITY_PRIORITY = {
        info: GLib::Notification::Priority::NORMAL,
        warning: GLib::Notification::Priority::HIGH,
        error: GLib::Notification::Priority::URGENT
      }.freeze

      SEVERITY_ICONS = {
        info: "dialog-information-symbolic",
        warning: "dialog-warning-symbolic",
        error: "dialog-error-symbolic"
      }.freeze

      def initialize(event_bus)
        @event_bus = event_bus
        @app = nil
      end

      def start
        @event_bus.on(:diagnostic) { |diag| notify(diag) }
      end

      def bind_app(app)
        @app = app
      end

      private

      def notify(diag)
        send_desktop(diag) if @app
      end

      def send_desktop(diag)
        notification = GLib::Notification.new(diag.rule_name)
        notification.body = diag.message
        notification.priority = SEVERITY_PRIORITY[diag.severity] || GLib::Notification::Priority::NORMAL
        notification.icon = Gio::ThemedIcon.new(SEVERITY_ICONS[diag.severity])
        @app.send_notification("ruby-pulse-#{diag.rule_name.tr(" ", "-")}", notification)
      end
    end
  end
end
