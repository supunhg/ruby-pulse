require "gtk4"
require "adwaita"

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

require_relative "../ui/application"

module RubyPulse
  class App
    def initialize
      @event_bus = Events::Bus.new
      @state = State::Manager.new(@event_bus)
      @scheduler = Scheduler::Runner.new(@event_bus)
      @diagnostics = Diagnostics::Engine.new(@event_bus, @state)
      @rules = Rules::Engine.new(@event_bus, @state)
      @plugins = Plugins::Loader.new(@event_bus)
      @timeline = Timeline::Recorder.new(@event_bus)
      @notifications = Notifications::Handler.new(@event_bus)
    end

    def run
      @event_bus.start
      register_collectors
      @scheduler.start
      @rules.start
      @diagnostics.start

      UI::Application.new(@event_bus, @state).run
    end

    private

    def register_collectors
      @scheduler.register(Collectors::Process.new, interval: 3)
      @scheduler.register(Collectors::Memory.new, interval: 2)
      @scheduler.register(Collectors::Cpu.new, interval: 2)
    end
  end
end
