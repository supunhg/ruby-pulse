# `ARCHITECTURE.md`

````md
# Ruby Pulse Architecture

A modern Linux-native system monitor and diagnostics platform built with Ruby, GTK4 and Linux observability primitives.

---

# Vision

Ruby Pulse is not another metrics dashboard.

The goal is to explain system behavior, diagnose performance issues, and provide actionable insight for Linux desktop users and developers.

Core principles:

- Linux-native
- Minimal and fast
- Explain behavior, not just metrics
- Developer workstation aware
- Modular and extensible
- Local-first
- Privacy-respecting
- Native GTK experience
- Plugin-driven architecture

---

# High-Level Architecture

```text
┌───────────────────────────────────────────────┐
│                    UI Layer                   │
│        GTK4 + libadwaita desktop app          │
└───────────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────┐
│               Application Core                │
│                                               │
│  - Event Bus                                  │
│  - State Manager                              │
│  - Diagnostics Engine                         │
│  - Rules Engine                               │
│  - Session Timeline                           │
│  - Plugin Runtime                             │
└───────────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────┐
│               Data Collection                 │
│                                               │
│  - Process Collector                          │
│  - Memory Collector                           │
│  - Thermal Collector                          │
│  - Network Collector                          │
│  - GPU Collector                              │
│  - Power/Battery Collector                    │
│  - Container Collector                        │
│  - Filesystem Collector                       │
└───────────────────────────────────────────────┘
                        │
                        ▼
┌───────────────────────────────────────────────┐
│                 Linux Sources                 │
│                                               │
│  /proc                                        │
│  /sys                                         │
│  cgroups v2                                   │
│  systemd                                      │
│  journalctl                                   │
│  lm-sensors                                   │
│  nvidia-smi / radeontop                       │
└───────────────────────────────────────────────┘
````

---

# Technology Stack

## Core Language

* Ruby 3.x

Reason:

* fast iteration
* expressive domain modeling
* plugin friendliness
* excellent DSL support
* rapid architecture evolution

---

## UI

* GTK4
* libadwaita
* ruby-gnome bindings

Why:

* native Linux UX
* low memory overhead
* modern GNOME integration
* avoids Electron overhead

---

## Persistence

* SQLite initially
* optional PostgreSQL later

Used for:

* session history
* timelines
* anomaly tracking
* diagnostics cache
* plugin state

---

## Optional Native Extensions

Future performance-critical collectors may use:

* Rust
* C

Only where required.

Ruby remains orchestration and application logic layer.

---

# Application Layers

---

# 1. UI Layer

Responsible for:

* rendering views
* graphs
* process explorer
* timeline visualization
* diagnostics display
* interaction handling

UI must remain dumb.

No business logic inside widgets.

---

## UI Structure

```text
ui/
├── windows/
├── views/
├── widgets/
├── charts/
├── dialogs/
├── overlays/
└── themes/
```

---

## Design Goals

* clean spacing
* low visual noise
* keyboard-friendly
* responsive updates
* minimal animations
* high information density without clutter

---

# 2. Application Core

Central orchestration layer.

Responsible for:

* app state
* event propagation
* diagnostics
* rule evaluation
* session management
* plugin coordination

---

## Core Modules

```text
core/
├── app.rb
├── state/
├── events/
├── scheduler/
├── diagnostics/
├── rules/
├── plugins/
├── timeline/
└── notifications/
```

---

## Event Bus

All subsystems communicate through events.

Example:

```ruby
emit :process_spike_detected, process
emit :thermal_warning, temperature
emit :battery_drain_detected
```

Advantages:

* loose coupling
* extensibility
* plugin compatibility
* simpler async architecture

---

# 3. Collection Layer

Responsible for acquiring system telemetry.

Collectors are isolated and stateless.

---

## Collector Design

Each collector:

* polls data
* normalizes output
* emits structured events

Example:

```ruby
class CpuCollector
  def collect
    {
      usage: 43.2,
      cores: [...]
    }
  end
end
```

---

## Collector Types

### Process Collector

Sources:

* `/proc/[pid]`

Tracks:

* CPU
* RSS
* threads
* IO
* children
* wakeups
* runtime

---

### Memory Collector

Sources:

* `/proc/meminfo`

Tracks:

* RAM
* swap
* pressure
* cache
* reclaim activity

---

### Thermal Collector

Sources:

* `/sys/class/thermal`

Tracks:

* temperatures
* throttling
* fan curves

---

### Power Collector

Tracks:

* battery drain
* estimated discharge causes
* wakeups
* power impact

---

### Container Collector

Tracks:

* Docker
* Podman
* cgroups
* resource isolation

---

# 4. Diagnostics Engine

This is the core product differentiator.

Purpose:
translate low-level metrics into explanations.

---

## Example Diagnostics

### Memory Leak Detection

```text
Electron process growing continuously
+1.2 GB in 15 minutes
Likely renderer leak
```

---

### Thermal Diagnosis

```text
High CPU package temperature caused by:
- Chromium video decode
- Docker container spikes
- GPU acceleration
```

---

### Idle Resource Waste

```text
7 inactive containers consuming 3.4 GB RAM
```

---

## Diagnostic Pipeline

```text
Raw Metrics
    ↓
Normalization
    ↓
Pattern Analysis
    ↓
Rule Evaluation
    ↓
Diagnostic Event
    ↓
UI Notification
```

---

# 5. Rules Engine

Ruby DSL-based detection system.

Purpose:
allow internal and external rules.

---

## Example

```ruby
rule "memory leak" do
  when rss_growth > 500.mb
  and cpu_idle?
  and process.electron?

  severity :warning

  message "Possible Electron memory leak detected"
end
```

---

## Benefits

* extensibility
* readable diagnostics
* plugin ecosystem
* AI-assisted future integration

---

# 6. Timeline Engine

Stores system events over time.

Purpose:
reconstruct system behavior.

---

## Timeline Examples

```text
10:41 CPU spike
10:42 fan escalation
10:43 thermal throttle
10:44 memory pressure critical
```

---

## Storage

Initial:

* SQLite event log

Future:

* compressed event storage
* time-series optimization

---

# 7. Plugin System

Ruby Pulse should support third-party modules.

---

## Plugin Capabilities

Plugins may:

* add collectors
* add diagnostics
* add UI panels
* define rules
* integrate external tools

---

## Plugin Sandbox

Plugins run:

* isolated
* permission-scoped
* event-driven

---

## Example Plugin Ideas

* NVIDIA analytics
* Kubernetes monitoring
* AI workload analysis
* Gaming mode diagnostics
* Audio pipeline debugging

---

# Process Model

Processes are represented as rich domain objects.

Not raw rows.

---

## Example

```ruby
ProcessEntity
  - pid
  - name
  - parent
  - children
  - cpu_usage
  - rss
  - gpu_usage
  - wakeups
  - power_score
  - diagnostics
```

---

# Performance Strategy

Ruby handles orchestration.

Heavy operations are minimized.

---

## Rules

* avoid blocking UI thread
* isolate collectors
* cache aggressively
* batch updates
* avoid excessive polling
* adaptive refresh rates

---

## Future Optimization

If required:

* Rust native extensions
* async collectors
* shared memory transport
* GPU graph acceleration

---

# Security Model

Ruby Pulse is local-first.

No telemetry by default.

No cloud dependency.

---

## Principles

* no hidden networking
* least privilege
* explicit permissions
* sandbox plugin execution
* user-visible diagnostics

---

# Accessibility

Required from the start.

---

## Support

* keyboard navigation
* screen readers
* scalable typography
* reduced motion mode
* high contrast themes

---

# Initial MVP

---

## Core Views

* Overview
* Processes
* Memory
* CPU
* GPU
* Network
* Power
* Diagnostics

---

## Initial Features

* process tree
* CPU graphs
* memory pressure detection
* thermal monitoring
* Docker detection
* battery impact scoring
* anomaly alerts
* timeline recording

---

# Future Roadmap

---

## v0.2

* plugin SDK
* rule editor
* advanced notifications
* process history replay

---

## v0.3

* AI-assisted diagnostics
* workload classification
* predictive alerts

---

## v0.4

* remote node monitoring
* cluster view
* distributed diagnostics

---

# Non-Goals

Ruby Pulse is NOT:

* an Electron app
* a terminal clone
* a server observability platform
* a cybersecurity dashboard
* an RGB metrics wall
* a cloud telemetry service

---

# Development Philosophy

Prioritize:

1. clarity
2. explainability
3. responsiveness
4. correctness
5. extensibility

Over:

* visual gimmicks
* excessive customization
* unnecessary abstraction
* premature optimization

---

# Repository Structure

```text
pulse/
├── app/
├── core/
├── collectors/
├── diagnostics/
├── rules/
├── plugins/
├── ui/
├── storage/
├── assets/
├── docs/
├── spec/
└── scripts/
```

---

# Long-Term Goal

Become the definitive Linux-native desktop observability platform for developers and power users.

Not merely a process viewer.
A system intelligence layer for Linux desktops.

```
```
