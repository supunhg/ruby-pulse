module RubyPulse
  module UI
    module Views
      class Processes
        attr_reader :title, :icon_name, :widget

        STATE_MAP = {
          "R" => "Running", "S" => "Sleeping", "D" => "Disk Sleep",
          "Z" => "Zombie",  "T" => "Stopped",  "t" => "Tracing Stop",
          "X" => "Dead"
        }.freeze

        NICE_LABELS = {
          -20 => "Realtime", -10 => "High", 0 => "Normal",
          10 => "Low", 19 => "Idle"
        }.freeze

        SIGNAL_NAMES = {
          terminate: :SIGTERM, force_kill: :SIGKILL,
          stop: :SIGSTOP, continue: :SIGCONT
        }.freeze

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Processes"
          @icon_name = "utilities-system-monitor-symbolic"
          @sort_attr = nil
          @sort_order = :ascending

          @store = Gio::ListStore.new(Collectors::ProcessEntity.gtype)
          @sort_model = Gtk::SortListModel.new(@store, nil)
          @selection = Gtk::SingleSelection.new(@sort_model)

          @widget = build_widget

          listen_for_updates
        end

        def focus_search
          @search_entry.grab_focus if @search_entry
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
          @count_label.halign = :start
          @count_label.hexpand = true
          header.append(@count_label)

          @search_entry = Gtk::SearchEntry.new
          @search_entry.placeholder_text = "Filter processes..."
          @search_entry.signal_connect :search_changed do
            filter_processes
          end
          header.append(@search_entry)

          scrolled = Gtk::ScrolledWindow.new
          scrolled.vexpand = true
          scrolled.child = build_column_view

          box.append(header)
          box.append(scrolled)
          box
        end

        def build_column_view
          @column_view = Gtk::ColumnView.new(@selection)
          @column_view.hexpand = true
          @column_view.vexpand = true

          @columns = []
          add_col("PID",     :pid,     width: 80,  align: :end)
          add_col("Name",    :name,    width: 250, ellipsize: true)
          add_col("CPU%",    :cpu,     width: 80,  align: :end, format: ->(v) { format("%.1f", v) })
          add_col("RSS",     :rss,     width: 100, align: :end, format: ->(v) { format_memory(v) })
          add_col("Threads", :threads, width: 80,  align: :end)
          add_col("State",   :state,   width: 100, align: :center, format: ->(v) { STATE_MAP[v] || v })

          setup_keyboard_shortcuts
          @column_view
        end

        def add_col(title, attr, width: -1, align: :start, format: nil, ellipsize: false)
          factory = Gtk::SignalListItemFactory.new

          factory.signal_connect :setup do |_f, list_item|
            label = Gtk::Label.new
            label.halign = align
            label.margin_start = 6
            label.margin_end = 6
            label.ellipsize = :end if ellipsize

            add_context_menu(label, list_item)

            list_item.child = label
          end

          factory.signal_connect :bind do |_f, list_item|
            item = list_item.item
            val = item.send(attr)
            list_item.child.text = format ? format.call(val) : val.to_s
          end

          column = Gtk::ColumnViewColumn.new(title, factory)
          column.resizable = true
          column.signal_connect "notify::sort-order" do
            apply_sort(attr, column)
          end
          @column_view.append_column(column)
          column
        end

        def add_context_menu(label, list_item)
          gesture = Gtk::GestureClick.new
          gesture.button = 3
          gesture.signal_connect :pressed do |_gest, _n, x, y|
            entity = list_item.item
            next unless entity
            @selection.selected_item = entity

            show_context_menu(label, entity, x, y)
          end
          label.add_controller(gesture)
        end

        def show_context_menu(widget, entity, x, y)
          menu = Gtk::PopoverMenu.new
          box = Gtk::Box.new(:vertical, 0)
          box.add_css_class("menu")

          add_menu_item(box, "Terminate", "action-unavailable-symbolic") do
            send_signal(entity.pid, entity.name, :terminate)
            menu.popdown
          end

          add_menu_item(box, "Force Kill", "dialog-error-symbolic", destructive: true) do
            menu.popdown
            confirm_force_kill(entity)
          end

          sep = Gtk::Separator.new(:horizontal)
          box.append(sep)

          add_menu_item(box, "Stop", "media-playback-pause-symbolic") do
            send_signal(entity.pid, entity.name, :stop)
            menu.popdown
          end

          add_menu_item(box, "Continue", "media-playback-start-symbolic") do
            send_signal(entity.pid, entity.name, :continue)
            menu.popdown
          end

          sep2 = Gtk::Separator.new(:horizontal)
          box.append(sep2)

          add_menu_item(box, "Priority...", "preferences-system-symbolic") do
            menu.popdown
            show_renice_dialog(entity)
          end

          menu.child = box
          menu.pointing_to = Gdk::Rectangle.new(x.to_i, y.to_i, 1, 1)
          widget.set_parent(menu)
          menu.popup
        end

        def add_menu_item(box, label, icon_name, destructive: false)
          btn = Gtk::Button.new
          hbox = Gtk::Box.new(:horizontal, 8)
          hbox.margin_start = 6
          hbox.margin_end = 6
          hbox.margin_top = 2
          hbox.margin_bottom = 2

          icon = Gtk::Image.new(icon_name: icon_name)
          icon.pixel_size = 16
          hbox.append(icon)

          text = Gtk::Label.new(label)
          text.halign = :start
          text.hexpand = true
          hbox.append(text)

          btn.child = hbox
          btn.halign = :fill
          btn.add_css_class("flat")
          btn.add_css_class("destructive-action") if destructive
          btn.signal_connect(:clicked) { yield }
          box.append(btn)
        end

        def confirm_force_kill(entity)
          native = @column_view.native
          return unless native

          dialog = Adwaita::AlertDialog.new
          dialog.heading = "Force Kill?"
          dialog.body = "Force quit #{entity.name} (PID #{entity.pid})? Unsaved data may be lost."
          dialog.add_response("cancel", "Cancel")
          dialog.add_response("force", "Force Kill")
          dialog.set_response_appearance("force", :destructive)
          dialog.default_response = "cancel"
          dialog.close_response = "cancel"

          dialog.choose(native) do |_source, result|
            response = dialog.choose_finish(result)
            send_signal(entity.pid, entity.name, :force_kill) if response == "force"
          end
        end

        def show_renice_dialog(entity)
          native = @column_view.native
          return unless native

          current_nice = 0
          begin
            current_nice = Process.getpriority(Process::PRIO_PROCESS, entity.pid)
          rescue Errno::ESRCH, Errno::EPERM
          end

          dialog = Adwaita::AlertDialog.new
          dialog.heading = "Change Priority"
          dialog.body = "Set priority for #{entity.name} (PID #{entity.pid})"
          dialog.add_response("cancel", "Cancel")
          dialog.add_response("set", "Set Priority")
          dialog.default_response = "cancel"
          dialog.close_response = "cancel"

          adj = Gtk::Adjustment.new(current_nice, -20, 19, 1, 5, 0)
          spin = Gtk::SpinButton.new(adjustment: adj)
          spin.numeric = true
          spin.snap_to_ticks = true
          spin.valign = :center
          spin.margin_top = 12
          dialog.extra_child = spin

          dialog.choose(native) do |_source, result|
            response = dialog.choose_finish(result)
            if response == "set"
              new_nice = spin.value.to_i
              renice_process(entity.pid, entity.name, new_nice)
            end
          end
        end

        def setup_keyboard_shortcuts
          controller = Gtk::EventControllerKey.new
          controller.signal_connect :key_pressed do |_ctrl, keyval, _code, state|
            handle_key(keyval, state)
          end
          @column_view.add_controller(controller)
        end

        def handle_key(keyval, state)
          ctrl = (state & Gdk::ModifierType::CONTROL_MASK) != 0
          entity = @selection.selected_item
          return false unless entity

          if keyval == Gdk::Keyval::KEY_Delete && !ctrl
            send_signal(entity.pid, entity.name, :terminate)
            true
          elsif keyval == Gdk::Keyval::KEY_Delete && ctrl
            confirm_force_kill(entity)
            true
          else
            false
          end
        end

        def send_signal(pid, name, action)
          sig = SIGNAL_NAMES[action]
          Process.kill(sig, pid)
          @event_bus.emit(:toast, {
            title: action.to_s.tr("_", " ").capitalize,
            message: "#{sig} sent to #{name} (PID #{pid})"
          })
        rescue Errno::ESRCH
          @event_bus.emit(:toast, {
            title: "Error",
            message: "Process #{pid} (#{name}) not found"
          })
        rescue Errno::EPERM
          @event_bus.emit(:toast, {
            title: "Permission Denied",
            message: "Cannot send #{sig} to #{name} (PID #{pid})"
          })
        end

        def renice_process(pid, name, nice_value)
          Process.setpriority(Process::PRIO_PROCESS, pid, nice_value)
          label = NICE_LABELS[nice_value] || nice_value.to_s
          @event_bus.emit(:toast, {
            title: "Priority Changed",
            message: "#{name} (PID #{pid}) set to #{label} (#{nice_value})"
          })
        rescue Errno::ESRCH
          @event_bus.emit(:toast, {
            title: "Error",
            message: "Process #{pid} (#{name}) not found"
          })
        rescue Errno::EPERM
          @event_bus.emit(:toast, {
            title: "Permission Denied",
            message: "Cannot renice #{name} (PID #{pid})"
          })
        end

        def listen_for_updates
          @event_bus.on :collector_update do |data|
            next unless data[:collector] == :process
            GLib::Idle.add(GLib::PRIORITY_DEFAULT_IDLE) do
              update_processes(data)
              false
            end
          end
        end

        def update_processes(data)
          processes = data[:processes] || []
          search = @search_entry.text.to_s.strip.downcase

          filtered = search.empty? ? processes : processes.select { |p| p.name.downcase.include?(search) }

          @store.splice(0, @store.n_items, filtered)

          total = processes.size
          visible = filtered.size
          @count_label.text = visible == total ? "#{total} processes" : "#{visible} of #{total} processes"
        end

        def filter_processes
          data = @state.latest(:process)
          update_processes(data) if data
        end

        def format_memory(kb)
          if kb >= 1_048_576
            format("%.1f GB", kb / 1_048_576.0)
          elsif kb >= 1024
            format("%.1f MB", kb / 1024.0)
          else
            format("%d KB", kb)
          end
        end
      end
    end
  end
end
