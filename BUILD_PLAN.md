# Ruby Pulse — Build Plan

> **File convention:** Update this file at the end of every major session to reflect the current state of the project and any changes to the plan.

---

## Current Phase: 5 — Plugin Runtime + Notifications

**Status:** ✅ Complete  
**Branch:** `dev`

---

## Technology Stack

| Layer | Choice | Status |
|---|---|---|
| Language | Ruby 3.x | ✅ |
| UI | GTK4 + libadwaita via `gtk4` + `adwaita` gems (Ruby-GNOME) | ✅ |
| Persistence | SQLite via `sqlite3` gem | ⏳ |
| Scheduling | Background threads with `sleep` + event bus | ✅ |
| Plugin sandbox | TBD (use `isolated` gem or `RubyVM::AbstractSyntaxTree`) | ❌ |
| Charts | Cairo on `Gtk::DrawingArea` with `set_draw_func` | ✅ |

---

## Build Phases

### Phase 0 — Application Shell ✅
- [x] `Adw::Application` with app ID `io.github.supunhg.ruby-pulse`
- [x] `Adw::ApplicationWindow` with `AdwToolbarView` + `AdwHeaderBar`
- [x] `Adw::ViewSwitcher` in header bar with `Adw::ViewStack`
- [x] 8 placeholder views: Overview, Processes, Memory, CPU, GPU, Network, Power, Diagnostics
- [x] Proper GTK main loop integration via signal_connect :activate
- [x] CSS theming foundation (assets/theme.css)

### Phase 1 — Process Collector + Process Tree ✅
- [x] Process collector reading `/proc/[pid]/status`, `/proc/[pid]/stat`, `/proc/[pid]/cmdline`
- [x] CPU% calculation via delta-based sampling (utime+stime vs total system)
- [x] `Gtk::ColumnView` with 6 columns: PID, Name, CPU%, RSS, Threads, State
- [x] Sortable columns with `Gtk::SortListModel` + `Gtk::CustomSorter`
- [x] Search/filter entry bar
- [x] Live process count indicator
- [x] Memory formatting (KB → MB/GB)
- [ ] Tree expansion for parent/child process hierarchy (next iteration)
- [ ] Process detail panel (sidebar or bottom sheet) (next iteration)
- [ ] Container detection for process grouping (next iteration)

### Phase 2 — Memory, CPU Collectors + Real-Time Charts ✅
- [x] CPU collector reading `/proc/stat` with per-core breakdown
- [x] CPU% delta calculation (idle vs total across samples)
- [x] Memory collector (already existed, extended with sparkline integration)
- [x] `ui/charts/sparkline.rb` — reusable Cairo `Gtk::DrawingArea` sparkline widget
  - Line + fill rendering with configurable colors
  - Auto-sizing within widget bounds
  - Configurable data range and max points (default 120)
- [x] Memory view: total/used/available cards + usage sparkline + swap sparkline
- [x] CPU view: total % sparkline + per-core grid (4 cols) with individual sparklines
- [x] 16-cycle core color palette
- [x] Thread-safe updates via GLib::Idle.add → queue_draw

### Phase 3 — Rules DSL + Diagnostics Engine ✅
- [x] `core/rules/engine.rb` — full DSL: `rule`, `severity`, `every` (cooldown), `check`, `message`
- [x] Built-in rules: High CPU, Low Memory, Zombie Processes, High Swap
- [x] `core/diagnostics/diagnostic.rb` — Diagnostic data class with severity/timestamp
- [x] `core/diagnostics/engine.rb` — active tracking, deduplication, resolve support
- [x] Diagnostics view with severity-colored cards (info/warning/error), icons, timestamps
- [x] Clear All button
- [x] Overview diagnostics count card
- [x] Event-driven evaluation on each collector update cycle

### Phase 4 — SQLite Timeline + Remaining Collectors ✅
- [x] `storage/database.rb` — SQLite-backed event store with auto-prune (24h)
- [x] Timeline recorder now persists diagnostics + periodic telemetry snapshots (every 5 cycles)
- [x] GPU collector — NVIDIA via `nvidia-smi` or fallback to `/sys/class/drm`
- [x] Thermal collector — reads all `/sys/class/thermal/thermal_zone*/temp` zones
- [x] Network collector — `/proc/net/dev` with RX/TX rate calculation (2s delta)
- [x] Power/Battery collector — `/sys/class/power_supply/BAT*` status, capacity, power draw
- [x] Container collector — Docker + Podman detection via `docker ps` / `podman ps`
- [x] GPU view: utilization sparkline, memory, temperature, auto-detection
- [x] Network view: per-interface rows with RX/TX rates, totals, dual sparklines
- [x] Power view: charge %, power draw, charging/discharging status
- [x] Overview: Temperature (hottest CPU zone) + container count cards

### Phase 5 — Plugin Runtime + Notifications ✅
- [x] `core/plugins/base.rb` — Plugin base class with `register_collector`, `register_rule`, lifecycle hooks
- [x] `core/plugins/loader.rb` — Plugin discovery via `**/*plugin.rb`, auto-subclass detection, error isolation
- [x] `plugins/example/plugin.rb` — Example plugin: uptime collector + weekly reboot rule
- [x] Desktop notifications via `GLib::Notification` (GNOME Shell integration)
  - Severity-based priority (info→normal, warning→high, error→urgent)
  - Themed icons per severity
- [x] In-app toast notifications via `Adw::ToastOverlay`
  - Auto-dismissing toasts (4s timeout)
  - Priority-based appearance (error = :high priority)
- [x] Plugin lifecycle: `on_activate` / `on_deactivate` hooks
- [x] `plugins/` directory convention for third-party extensions

### Phase 6 — Polish
- [ ] Keyboard navigation
- [ ] Dark/light theme support
- [ ] Adaptive breakpoints (desktop → mobile layout)
- [ ] Accessibility (screen reader labels, reduced motion)
- [ ] Native packaging (Flatpak/AppImage)

---

## Directory Structure

```
ruby-pulse/
├── app/              # Entry point
│   └── main.rb
├── core/             # Application core
│   ├── app.rb
│   ├── events/       # Event bus
│   ├── state/        # State manager
│   ├── scheduler/    # Collector scheduling
│   ├── diagnostics/  # Diagnostics engine
│   ├── rules/        # Rules DSL engine
│   ├── plugins/      # Plugin loader
│   ├── timeline/     # Session timeline
│   └── notifications/
├── collectors/       # Data collectors
│   ├── process.rb
│   ├── memory.rb
│   ├── cpu.rb
│   ├── gpu.rb
│   ├── thermal.rb
│   ├── network.rb
│   ├── power.rb
│   ├── container.rb
│   └── models/
│       └── process_entity.rb
├── core/
│   ├── app.rb
│   ├── events/
│   ├── state/
│   ├── scheduler/
│   ├── diagnostics/
│   │   ├── diagnostic.rb
│   │   └── engine.rb
│   ├── rules/
│   │   └── engine.rb
│   ├── plugins/
│   ├── timeline/
│   └── notifications/
├── diagnostics/      # (merged into core/diagnostics/)
├── rules/            # Built-in rules
│   ├── high_cpu.rb
│   ├── memory_pressure.rb
│   ├── zombie_processes.rb
│   └── high_swap.rb
├── plugins/          # Plugins
│   └── example/
│       └── plugin.rb
├── ui/               # GTK4 UI layer
│   ├── windows/
│   ├── views/
│   ├── widgets/
│   ├── charts/
│   ├── dialogs/
│   ├── overlays/
│   └── themes/
├── storage/          # SQLite / persistence
│   └── database.rb
├── assets/
├── docs/
├── spec/             # RSpec tests
├── scripts/
├── Gemfile
├── Rakefile
└── BUILD_PLAN.md     # ← This file (update each session)
```
