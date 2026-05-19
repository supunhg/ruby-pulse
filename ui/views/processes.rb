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

        def initialize(event_bus, state)
          @event_bus = event_bus
          @state = state
          @title = "Processes"
          @icon_name = "utilities-system-monitor-symbolic"
          @sort_attr = nil
          @sort_order = :ascending

          @store = Gio::ListStore.new(Collectors::ProcessEntity.gtype)
          @selection = Gtk::SingleSelection.new(@store)
          @sort_model = Gtk::SortListModel.new(@selection, nil)

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
          @column_view = Gtk::ColumnView.new(@sort_model)
          @column_view.hexpand = true
          @column_view.vexpand = true

          @columns = []
          add_col("PID",     :pid,     width: 80,  align: :end)
          add_col("Name",    :name,    width: 250, ellipsize: true)
          add_col("CPU%",    :cpu,     width: 80,  align: :end, format: ->(v) { format("%.1f", v) })
          add_col("RSS",     :rss,     width: 100, align: :end, format: ->(v) { format_memory(v) })
          add_col("Threads", :threads, width: 80,  align: :end)
          add_col("State",   :state,   width: 100, align: :center, format: ->(v) { STATE_MAP[v] || v })

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

        def apply_sort(attr, column)
          @sort_attr = attr
          order = column.sort_order

          @column_view.columns.each { |c| c.sort_indicator = (c == column) }

          @sort_model.sorter = Gtk::CustomSorter.new do |a, b|
            a_val = a.send(attr)
            b_val = b.send(attr)
            cmp = a_val.is_a?(String) ? a_val.downcase <=> b_val.downcase : a_val <=> b_val
            order == :ascending ? cmp : -cmp
          end
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

          # Rebuild store via splice: remove all, then insert
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
