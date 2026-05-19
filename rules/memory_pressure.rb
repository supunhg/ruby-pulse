rule "Low Memory" do
  severity :error
  every 60

  check do |state|
    mem = state.latest(:memory)
    next false unless mem && mem[:metrics]
    total = mem[:metrics][:total].to_f
    available = mem[:metrics][:available].to_f
    total > 0 && (available / total) < 0.10
  end

  message do |state|
    mem = state.latest(:memory)[:metrics]
    total_gb = mem[:total] / 1_048_576.0
    avail_gb = mem[:available] / 1_048_576.0
    "Only #{format('%.1f', avail_gb)} GB available of #{format('%.1f', total_gb)} GB total"
  end
end
