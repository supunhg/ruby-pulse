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
      VIEW_KEYS = %i[overview processes memory cpu gpu network power diagnostics].freeze

      def initialize(application, event_bus, state)
        super(application)
        @event_bus = event_bus
        @state = state

        set_title "Ruby Pulse"
        set_default_size 1200, 800
        set_size_request 360, 300

        build_ui
        apply_css
        setup_shortcuts
        setup_accessibility
        setup_breakpoints
      end

      private

      def build_ui
        toolbar_view = Adw::ToolbarView.new

        header_bar = Adw::HeaderBar.new

        @theme_btn = Gtk::ToggleButton.new
        @theme_btn.icon_name = "weather-clear-night-symbolic"
        @theme_btn.tooltip_text = "Toggle Dark Mode"
        @theme_btn.valign = :center
        @theme_btn.signal_connect(:toggled) { toggle_theme }
        header_bar.pack_end(@theme_btn)

        @about_btn = Gtk::MenuButton.new
        @about_btn.icon_name = "open-menu-symbolic"
        @about_btn.tooltip_text = "Menu"
        @about_btn.valign = :center

        about_menu = Gtk::PopoverMenu.new
        about_box = Gtk::Box.new(:vertical, 0)
        about_box.add_css_class("menu")

        about_item = Gtk::Button.new(label: "About Ruby Pulse")
        about_item.halign = :fill
        about_item.signal_connect(:clicked) { show_about }
        about_box.append(about_item)

        about_menu.child = about_box
        @about_btn.popover = about_menu
        header_bar.pack_end(@about_btn)

        view_switcher = Adw::ViewSwitcher.new
        @view_stack = Adw::ViewStack.new

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
          @view_stack.add_titled_with_icon(view.widget, key.to_s, view.title, view.icon_name)
        end

        view_switcher.stack = @view_stack

        header_bar.title_widget = view_switcher
        toolbar_view.add_top_bar(header_bar)
        toolbar_view.content = @view_stack

        @status_bar = Gtk::Box.new(:horizontal, 6)
        @status_bar.margin_start = 8
        @status_bar.margin_end = 8
        @status_bar.margin_top = 2
        @status_bar.margin_bottom = 2
        @status_bar.add_css_class("status-bar")

        @status_label = Gtk::Label.new
        @status_label.opacity = 0.5
        @status_label.halign = :start
        @status_label.hexpand = true
        @status_bar.append(@status_label)

        toolbar_view.add_bottom_bar(@status_bar)

        @toast_overlay = Adw::ToastOverlay.new
        @toast_overlay.child = toolbar_view
        set_content(@toast_overlay)

        listen_for_diagnostics
        listen_for_toasts
        update_status_bar
      end

      def setup_shortcuts
        controller = Gtk::EventControllerKey.new
        controller.signal_connect :key_pressed do |_ctrl, keyval, _code, state|
          handle_shortcut(keyval, state)
        end
        add_controller(controller)
      end

      def handle_shortcut(keyval, state)
        ctrl = (state & Gdk::ModifierType::CONTROL_MASK) != 0
        shift = (state & Gdk::ModifierType::SHIFT_MASK) != 0

        if ctrl && keyval == Gdk::Keyval::KEY_q
          close_request
          true
        elsif ctrl && keyval == Gdk::Keyval::KEY_Tab
          if shift
            prev_view
          else
            next_view
          end
          true
        elsif ctrl && keyval == Gdk::Keyval::KEY_d
          switch_to_view(:diagnostics)
          true
        elsif ctrl && keyval == Gdk::Keyval::KEY_f
          focus_process_search
          true
        elsif ctrl && keyval == Gdk::Keyval::KEY_i
          show_about
          true
        elsif ctrl && keyval >= Gdk::Keyval::KEY_1 && keyval <= Gdk::Keyval::KEY_8
          idx = keyval - Gdk::Keyval::KEY_1
          switch_to_view(VIEW_KEYS[idx]) if idx < VIEW_KEYS.size
          true
        elsif keyval == Gdk::Keyval::KEY_F5
          true
        else
          false
        end
      end

      def next_view
        return if @views.size < 2
        current = @view_stack.visible_child_name
        names = @views.keys.map(&:to_s)
        idx = names.index(current) || 0
        switch_to_view(VIEW_KEYS[(idx + 1) % names.size])
      end

      def prev_view
        return if @views.size < 2
        current = @view_stack.visible_child_name
        names = @views.keys.map(&:to_s)
        idx = names.index(current) || 0
        switch_to_view(VIEW_KEYS[(idx - 1) % names.size])
      end

      def switch_to_view(key)
        name = key.to_s
        @view_stack.pages.each do |page|
          if page.name == name || page.title.downcase == name
            @view_stack.visible_child = page.child
            break
          end
        end
      end

      def focus_process_search
        @views[:processes]&.focus_search
      end

      def show_about
        dialog = Adw::AboutDialog.new
        dialog.application_name = "Ruby Pulse"
        dialog.version = "0.1.0"
        dialog.developer_name = "Supun HG"
        dialog.website = "https://github.com/supunhg/ruby-pulse"
        dialog.issue_url = "https://github.com/supunhg/ruby-pulse/issues"
        dialog.add_credit_section("Built With", ["Ruby #{RUBY_VERSION}", "GTK4", "libadwaita", "SQLite"])
        dialog.translator_credits = ""
        dialog.present(self)
      end

      def toggle_theme
        manager = Adw::StyleManager.get_default
        manager.color_scheme = @theme_btn.active? ? :prefer_dark : :prefer_light
        @theme_btn.icon_name = @theme_btn.active? ? "weather-clear-symbolic" : "weather-clear-night-symbolic"
      end

      def setup_accessibility
        accessible_role = Gtk::AccessibleRole::APPLICATION
      end

      def setup_breakpoints
        bp = Adw::Breakpoint.new(Adw::BreakpointCondition.parse("max-width: 600px"))
        bp.signal_connect :apply do
          @status_bar.hide
        end
        bp.signal_connect :unapply do
          @status_bar.show
        end
        add_breakpoint(bp)
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

        @event_bus.on :diagnostics_count do |count|
          GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
            set_title count > 0 ? "Ruby Pulse (#{count})" : "Ruby Pulse"
            false
          end
        end
      end

      def listen_for_toasts
        @event_bus.on :toast do |data|
          GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
            toast = Adw::Toast.new(data[:message])
            toast.title = data[:title] if data[:title]
            toast.timeout = 4
            @toast_overlay.add_toast(toast)
            false
          end
        end
      end

      def update_status_bar
        GLib::Timeout.add_seconds(5) do
          GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
            now = Time.now.strftime("%H:%M:%S")
            @status_label.text = "Last updated: #{now}"
            false
          end
          true
        end
      end

      def apply_css
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
