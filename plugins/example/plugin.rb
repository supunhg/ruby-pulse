class UptimeCollector
  def collect
    uptime_secs = File.read("/proc/uptime").split.first.to_f
    days = (uptime_secs / 86_400).to_i
    hours = ((uptime_secs % 86_400) / 3600).to_i
    minutes = ((uptime_secs % 3600) / 60).to_i
    {
      collector: :uptime,
      uptime_secs: uptime_secs.round(0),
      formatted: "#{days}d #{hours}h #{minutes}m",
      timestamp: Time.now
    }
  rescue
    { collector: :uptime, uptime_secs: 0, formatted: "unknown" }
  end
end

class ExamplePlugin < RubyPulse::Plugins::Base
  def initialize(event_bus, scheduler, rules_engine)
    super
    @name = "Example Plugin"
    @version = "0.1.0"
    @description = "Demonstrates the Ruby Pulse plugin API"
  end

  def on_activate
    log "activating..."
    register_collector(UptimeCollector, interval: 10)
    register_rule("System Uptime Alert") do
      severity :info
      every 3600
      check do |state|
        uptime = state.latest(:uptime)
        uptime && uptime[:uptime_secs].to_i > 86_400 * 7
      end
      message do |state|
        uptime = state.latest(:uptime)
        "System has been up for #{uptime[:formatted]} — consider rebooting"
      end
    end
    log "activated"
  end

  def on_deactivate
    log "deactivated"
  end
end
