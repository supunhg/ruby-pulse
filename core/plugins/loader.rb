require_relative "base"

module RubyPulse
  module Plugins
    class Loader
      def initialize(event_bus, scheduler, rules_engine)
        @event_bus = event_bus
        @scheduler = scheduler
        @rules = rules_engine
        @plugins = []
      end

      def discover(path = nil)
        plugin_dir = path || File.expand_path("../../plugins", __dir__)
        Dir["#{plugin_dir}/**/*plugin.rb"].sort.each do |file|
          load_plugin_file(file)
        end
        self
      end

      def activate_all
        @plugins.each { |p| activate(p) }
      end

      def deactivate_all
        @plugins.reverse_each { |p| deactivate(p) }
      end

      def list
        @plugins.map { |p| { name: p.name, version: p.version, description: p.description } }
      end

      private

      def load_plugin_file(path)
        before = Base.subclasses.dup
        Object.new.instance_eval(File.read(path), path)
        new_classes = Base.subclasses - before
        return if new_classes.empty?

        klass = new_classes.first
        instance = klass.new(@event_bus, @scheduler, @rules)
        @plugins << instance
        puts "  loaded plugin: #{instance.name} v#{instance.version}"
      rescue => e
        warn "  plugin load failed (#{File.basename(path)}): #{e.message}"
      end

      def activate(plugin)
        plugin.on_activate
        puts "  activated plugin: #{plugin.name}"
      rescue => e
        warn "  plugin #{plugin.name} activation failed: #{e.message}"
      end

      def deactivate(plugin)
        plugin.on_deactivate
      rescue => e
        warn "  plugin #{plugin.name} deactivation failed: #{e.message}"
      end
    end
  end
end
