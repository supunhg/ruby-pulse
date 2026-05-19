rule "Zombie Processes" do
  severity :warning
  every 120

  check do |state|
    procs = state.latest(:process)
    return false unless procs && procs[:processes]
    procs[:processes].any? { |p| p.state == "Z" }
  end

  message do |state|
    zombies = state.latest(:process)[:processes].select { |p| p.state == "Z" }
    names = zombies.map { |z| "#{z.name} (#{z.pid})" }.join(", ")
    "#{zombies.size} zombie process(es): #{names}"
  end
end
