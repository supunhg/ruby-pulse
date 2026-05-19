# Ruby Pulse — Design Vision

> Design research captured after analyzing btop++, Mission Center, GNOME System Monitor,
> Windows 11 Task Manager, macOS Activity Monitor, and Resources.

## Core Philosophy: "Calm Monitoring"

Present information clearly without creating anxiety. Use progressive disclosure
(summary → detail) through expandable rows and tabbed sections.

## Color & Theming

- Follow Adwaita light/dark natively (no custom theme engine)
- Offer a "Pulse" color accent option: CPU→green, memory→amber, disk→blue, network→purple
- Use semantic color mapping for graphs to aid quick scanning

## Layout

- **AdwNavigationSplitView** — sidebar (icon + label) + content pane
- Processes tab: top section = compact resource bars, bottom = process list
- Cards for summary stats (rounded, spaced, with subtle shadows)
- Sparklines inline (not full-width) to conserve space

## Process List UX (Current Priority)

- Right-click context menu (`Gtk::PopoverMenu`) with:
  - Quick actions (no confirm): Terminate (SIGTERM), Stop, Continue
  - Destructive action: Force Kill (SIGKILL) with `Adw::AlertDialog` confirmation
  - Priority submenu: Realtime/Hi/Normal/Low/Idle with radio indicators
  - Separator
  - Show Details → inline expandable row (future)

- Single-click for selection, Delete→SIGTERM, Ctrl+Delete→SIGKILL
- Toast feedback for all actions (success/error)
- Multi-select support (Shift+click, Ctrl+click) for batch ops (future)

## Process Details (Future)

- Double-click → inline expandable detail row showing:
  - PID, PPID, priority, command line, thread count, open files
  - Mini CPU/memory sparkline
- Bottom sheet or sidebar for full detail view

## Graphs & Charts

- Sparklines with fill gradients, rendered via Cairo on Gtk::DrawingArea
- Auto-range within widget bounds
- Configurable colors per data type
- Compact for per-core, larger for summary

## Header Toolbar

- AdwViewSwitcher for tab navigation (or sidebar in split view)
- Theme toggle (sun/moon)
- Hamburger menu: About, Preferences, Export

## Status Bar

- "Last updated: HH:MM:SS" with 5s refresh
- Diagnostic count badge
- Auto-hides below 600px breakpoint

## Packaging

- Flatpak with org.gnome.Platform//47 runtime
- Desktop file + AppStream metainfo
- Application icon (SVG, symbolic)
