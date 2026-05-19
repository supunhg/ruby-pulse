rule "High Swap Usage" do
  severity :warning
  every 60

  check do |state|
    mem = state.latest(:memory)
    next false unless mem && mem[:metrics]
    swap_total = mem[:metrics][:swap_total].to_f
    swap_free = mem[:metrics][:swap_free].to_f
    swap_total > 0 && ((swap_total - swap_free) / swap_total) > 0.50
  end

  message do |state|
    mem = state.latest(:memory)[:metrics]
    used = mem[:swap_total] - mem[:swap_free]
    pct = (used.to_f / mem[:swap_total] * 100).round(1)
    "Swap at #{pct}% (#{format_memory(used)} of #{format_memory(mem[:swap_total])})"
  end

  def format_memory(kb)
    kb >= 1_048_576 ? format("%.1f GB", kb / 1_048_576.0) : format("%.1f MB", kb / 1024.0)
  end
end
