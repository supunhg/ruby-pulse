require_relative "views/overview"
require_relative "views/processes"
require_relative "views/memory"
require_relative "views/cpu"
require_relative "views/gpu"
require_relative "views/network"
require_relative "views/power"
require_relative "views/diagnostics"

module RubyPulse
  module UI
    class ApplicationWindow < Adw::ApplicationWindow
      def initialize(application, event_bus, state)
        super(application: application)
        @event_bus = event_bus
        @state = state

        set_title "Ruby Pulse"
        set_default_size 1200, 800

        build_ui
        apply_theme
      end

      private

      def build_ui
        toolbar_view = Adw::ToolbarView.new

        header_bar = Adw::HeaderBar.new
        view_switcher = Adw::ViewSwitcher.new
        view_stack = Adw::ViewStack.new

        @views = {
          overview:    Views::Overview.new(@event_bus, @state),
          processes:   Views::Processes.new(@event_bus, @state),
          memory:      Views::Memory.new(@event_bus, @state),
          cpu:         Views::Cpu.new(@event_bus, @state),
          gpu:         Views::Gpu.new(@event_bus, @state),
          network:     Views::Network.new(@event_bus, @state),
          power:       Views::Power.new(@event_bus, @state),
          diagnostics: Views::Diagnostics.new(@event_bus, @state)
        }

        @views.each do |key, view|
          page = Adw::ViewStackPage.new
          page.title = view.title
          page.child = view.widget
          page.icon_name = view.icon_name
          view_stack.add(page)
        end

        view_switcher.stack = view_stack

        header_bar.title_widget = view_switcher
        toolbar_view.add_top_bar(header_bar)
        toolbar_view.content = view_stack

        @toast_overlay = Adw::ToastOverlay.new
        @toast_overlay.child = toolbar_view
        set_content(@toast_overlay)

        listen_for_diagnostics
      end

      def listen_for_diagnostics
        @event_bus.on :diagnostic do |diag|
          GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
            toast = Adw::Toast.new(diag.message)
            toast.title = diag.rule_name
            toast.priority = diag.severity == :error ? :high : :normal
            toast.timeout = 4
            @toast_overlay.add_toast(toast)
            false
          end
        end
      end

      def apply_theme
        css_path = File.expand_path("../assets/theme.css", __dir__)
        return unless File.exist?(css_path)

        provider = Gtk::CssProvider.new
        provider.load_from_path(css_path)
        Gtk::StyleContext.add_provider_for_display(
          display,
          provider,
          Gtk::StyleProvider::PRIORITY_APPLICATION
        )
      end
    end
  end
end
