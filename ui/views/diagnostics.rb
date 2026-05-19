require "cgi"

module RubyPulse
  module UI
    module Views
      class Diagnostics
        attr_reader :title, :icon_name, :widget

        SEVERITY_ICONS = {
          info: "dialog-information-symbolic",
          warning: "dialog-warning-symbolic",
          error: "dialog-error-symbolic"
        }.freeze

        SEVERITY_CSS = {
          info: "diagnostic-info",
          warning: "diagnostic-warning",
          error: "diagnostic-error"
        }.freeze

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Diagnostics"
          @icon_name = "emblem-important-symbolic"
          @rows = {}
          @widget = build_widget

          listen_for_updates
        end

        private

        def build_widget
          box = Gtk::Box.new(:vertical, 0)

          header = Gtk::Box.new(:horizontal, 6)
          header.margin_start = 12
          header.margin_end = 12
          header.margin_top = 6
          header.margin_bottom = 6

          @count_label = Gtk::Label.new
          @count_label.markup = "<b>Active Diagnostics: 0</b>"
          @count_label.halign = :start
          @count_label.hexpand = true
          header.append(@count_label)

          @clear_btn = Gtk::Button.new(label: "Clear All")
          @clear_btn.signal_connect(:clicked) { clear_all }
          header.append(@clear_btn)

          scrolled = Gtk::ScrolledWindow.new
          scrolled.vexpand = true

          @list_box = Gtk::ListBox.new
          @list_box.selection_mode = :none
          @list_box.add_css_class("boxed-list")
          scrolled.child = @list_box

          empty_row = Gtk::ListBoxRow.new
          empty_label = Gtk::Label.new("No active diagnostics")
          empty_label.margin_top = 24
          empty_label.margin_bottom = 24
          empty_label.halign = :center
          empty_label.opacity = 0.5
          empty_row.child = empty_label
          @list_box.append(empty_row)
          @empty_row = empty_row

          box.append(header)
          box.append(scrolled)
          box
        end

        def build_diagnostic_row(diag)
          row = Gtk::ListBoxRow.new
          row.add_css_class(SEVERITY_CSS[diag.severity] || "diagnostic-info")

          hbox = Gtk::Box.new(:horizontal, 8)
          hbox.margin_start = 12
          hbox.margin_end = 12
          hbox.margin_top = 10
          hbox.margin_bottom = 10

          icon = Gtk::Image.new
          icon.icon_name = SEVERITY_ICONS[diag.severity] || "dialog-information-symbolic"
          icon.pixel_size = 20
          icon.valign = :start
          hbox.append(icon)

          text_box = Gtk::Box.new(:vertical, 2)
          text_box.hexpand = true

          title = Gtk::Label.new
          title.markup = "<b>#{CGI.escape_html(diag.rule_name)}</b>"
          title.halign = :start
          title.xalign = 0
          text_box.append(title)

          msg = Gtk::Label.new(diag.message)
          msg.halign = :start
          msg.xalign = 0
          msg.wrap = true
          msg.opacity = 0.8
          text_box.append(msg)

          time = Gtk::Label.new(diag.timestamp.strftime("%H:%M:%S"))
          time.halign = :start
          time.xalign = 0
          time.opacity = 0.4
          time.margin_top = 2
          text_box.append(time)

          hbox.append(text_box)
          row.child = hbox
          row
        end

        def listen_for_updates
          @event_bus.on :diagnostic do |diag|
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              add_diagnostic(diag)
              false
            end
          end

          @event_bus.on :diagnostic_resolved_ui do |rule_name|
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              remove_diagnostic(rule_name)
              false
            end
          end
        end

        def add_diagnostic(diag)
          return if @rows[diag.rule_name]

          @empty_row.hide if @empty_row
          row = build_diagnostic_row(diag)
          @rows[diag.rule_name] = row
          @list_box.prepend(row)
          update_count
        end

        def remove_diagnostic(rule_name)
          row = @rows.delete(rule_name)
          @list_box.remove(row) if row
          @empty_row.show if @rows.empty?
          update_count
        end

        def clear_all
          @rows.each_key { |name| remove_diagnostic(name) }
        end

        def update_count
          @count_label.markup = "<b>Active Diagnostics: #{@rows.size}</b>"
        end
      end
    end
  end
end
