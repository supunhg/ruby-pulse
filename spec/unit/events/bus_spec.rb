RSpec.describe RubyPulse::Events::Bus do
  subject(:bus) { described_class.new }

  it "emits events to registered listeners" do
    received = []
    bus.on(:test) { |p| received << p }
    bus.emit(:test, :payload)
    expect(received).to eq([:payload])
  end

  it "supports multiple listeners per event" do
    results = []
    bus.on(:multi) { results << 1 }
    bus.on(:multi) { results << 2 }
    bus.emit(:multi)
    expect(results).to contain_exactly(1, 2)
  end
end
