module RubyPulse
  module Collectors
    class ProcessEntity < GObject::Object
      type_register

      attr_reader :pid, :name, :cpu, :rss, :threads, :state, :ppid

      def initialize(pid:, name:, cpu: 0.0, rss: 0, threads: 1, state: "?", ppid: 0)
        super()
        @pid = pid
        @name = name
        @cpu = cpu
        @rss = rss
        @threads = threads
        @state = state
        @ppid = ppid
      end
    end
  end
end
