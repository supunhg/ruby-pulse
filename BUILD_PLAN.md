# Ruby Pulse — Build Plan

> **File convention:** Update this file at the end of every major session to reflect the current state of the project and any changes to the plan.

---

## Current Phase: 0 — Application Shell

**Status:** ✅ Complete  
**Branch:** `dev`

---

## Technology Stack

| Layer | Choice | Status |
|---|---|---|
| Language | Ruby 3.x | ✅ |
| UI | GTK4 + libadwaita via `gtk4` + `adwaita` gems (Ruby-GNOME) | ✅ |
| Persistence | SQLite via `sqlite3` gem | ⏳ |
| Scheduling | `Concurrent::TimerTask` / background threads | ⏳ |
| Plugin sandbox | TBD (use `isolated` gem or `RubyVM::AbstractSyntaxTree`) | ❌ |
| Charts | Cairo on `Gtk::DrawingArea` with `Gtk::TickCallback` | ❌ |

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

### Phase 2 — Memory, CPU Collectors + Real-Time Charts
- [ ] Memory collector (`/proc/meminfo`)
- [ ] CPU collector (`/proc/stat`)
- [ ] Cairo-based sparkline charts on `Gtk::DrawingArea`
- [ ] Adaptive refresh rates (e.g., 1s when visible, pause when hidden)

### Phase 3 — Rules DSL + Diagnostics Engine
- [ ] `rule "name" do ... end` DSL parser
- [ ] Built-in rules: memory leak detection, thermal warning, idle resource waste
- [ ] Diagnostics panel showing active and historical issues
- [ ] Event-driven rule evaluation

### Phase 4 — SQLite Timeline + Remaining Collectors
- [ ] SQLite schema for session events
- [ ] Timeline recorder wiring
- [ ] GPU collector (`nvidia-smi` / `radeontop`)
- [ ] Thermal collector (`/sys/class/thermal`)
- [ ] Network collector (`/proc/net/dev`)
- [ ] Power/Battery collector
- [ ] Container collector (Docker/Podman/cgroups)

### Phase 5 — Plugin Runtime + Notifications
- [ ] Isolated plugin loading
- [ ] Plugin API (register collectors, rules, UI panels)
- [ ] In-app notifications
- [ ] Desktop notifications via libnotify/GLib

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
│   └── memory.rb
├── diagnostics/      # Diagnostic definitions
├── rules/            # Rule definitions
├── plugins/          # Third-party plugins
├── ui/               # GTK4 UI layer
│   ├── windows/
│   ├── views/
│   ├── widgets/
│   ├── charts/
│   ├── dialogs/
│   ├── overlays/
│   └── themes/
├── storage/          # SQLite / persistence
├── assets/
├── docs/
├── spec/             # RSpec tests
├── scripts/
├── Gemfile
├── Rakefile
└── BUILD_PLAN.md     # ← This file (update each session)
```
