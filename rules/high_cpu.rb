rule "High CPU Usage" do
  severity :warning
  every 30

  check do |state|
    cpu = state.latest(:cpu)
    cpu && cpu[:total].to_f > 90
  end

  message do |state|
    pct = state.latest(:cpu)[:total]
    "CPU sustained at #{pct}% — check for runaway processes"
  end
end
