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
      @scheduler.start
      @rules.start
      @diagnostics.start

      UI::Application.new(@event_bus, @state).run
    end
  end
end
