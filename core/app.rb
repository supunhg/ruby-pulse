require "gtk4"
require "adwaita"
Adw = Adwaita unless defined?(Adw)

require_relative "events/bus"
require_relative "state/manager"
require_relative "scheduler/runner"
require_relative "diagnostics/engine"
require_relative "rules/engine"
require_relative "plugins/loader"
require_relative "timeline/recorder"
require_relative "notifications/handler"

require_relative "../collectors/process"
require_relative "../collectors/memory"
require_relative "../collectors/cpu"
require_relative "../collectors/gpu"
require_relative "../collectors/thermal"
require_relative "../collectors/network"
require_relative "../collectors/power"
require_relative "../collectors/container"

require_relative "../ui/application"

module RubyPulse
  class App
    def initialize
      @event_bus = Events::Bus.new
      @state = State::Manager.new(@event_bus)
      @scheduler = Scheduler::Runner.new(@event_bus)
      @diagnostics = Diagnostics::Engine.new(@event_bus, @state)
      @rules = Rules::Engine.new(@event_bus, @state)
      @plugins = Plugins::Loader.new(@event_bus, @scheduler, @rules)
      @timeline = Timeline::Recorder.new(@event_bus)
      @notifications = Notifications::Handler.new(@event_bus)
    end

    def run
      @event_bus.start
      register_collectors
      @scheduler.start
      load_rules
      load_plugins
      @rules.start
      @diagnostics.start
      @timeline.start
      @notifications.start

      UI::Application.new(@event_bus, @state, @notifications).run
    end

    private

    def register_collectors
      @scheduler.register(Collectors::Process.new, interval: 3)
      @scheduler.register(Collectors::Memory.new, interval: 2)
      @scheduler.register(Collectors::Cpu.new, interval: 2)
      @scheduler.register(Collectors::Gpu.new, interval: 5)
      @scheduler.register(Collectors::Thermal.new, interval: 5)
      @scheduler.register(Collectors::Network.new, interval: 2)
      @scheduler.register(Collectors::Power.new, interval: 5)
      @scheduler.register(Collectors::Container.new, interval: 10)
    end

    def load_rules
      rules_dir = File.expand_path("../rules", __dir__)
      Dir["#{rules_dir}/*.rb"].sort.each do |path|
        @rules.instance_eval(File.read(path), path)
      end
    end

    def load_plugins
      @plugins.discover
      @plugins.activate_all
    end
  end
end
