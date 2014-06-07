require 'spec_helper'

describe Finance::REfficientFrontier do

  it "returns empty array for no tickers" do
    expect(Finance::REfficientFrontier.build([])).to eql([])
  end

  it "returns correct values for 1 ticker" do
    expect(Finance::REfficientFrontier.build(["EEM"])).to eql([
      {"EEM" => 1.0}
    ])
  end

  it "returns correct values for 2 tickers" do
    expect(Finance::REfficientFrontier.build(["EEM", "GSG"])).to eql([
      {"EEM" => 0.00, "GSG" => 1.00},
      {"EEM" => 0.05, "GSG" => 0.95},
      {"EEM" => 0.10, "GSG" => 0.90},
      {"EEM" => 0.15, "GSG" => 0.85},
      {"EEM" => 0.20, "GSG" => 0.80},
      {"EEM" => 0.25, "GSG" => 0.75},
      {"EEM" => 0.30, "GSG" => 0.70},
      {"EEM" => 0.35, "GSG" => 0.65},
      {"EEM" => 0.40, "GSG" => 0.60},
      {"EEM" => 0.45, "GSG" => 0.55},
      {"EEM" => 0.50, "GSG" => 0.50},
      {"EEM" => 0.55, "GSG" => 0.45},
      {"EEM" => 0.60, "GSG" => 0.40},
      {"EEM" => 0.65, "GSG" => 0.35},
      {"EEM" => 0.70, "GSG" => 0.30},
      {"EEM" => 0.75, "GSG" => 0.25},
      {"EEM" => 0.80, "GSG" => 0.20},
      {"EEM" => 0.85, "GSG" => 0.15},
      {"EEM" => 0.90, "GSG" => 0.10},
      {"EEM" => 0.95, "GSG" => 0.05},
      {"EEM" => 1.00, "GSG" => 0.00}
    ])
  end

  describe "with RServe" do
    it "returns correct values for 3 tickers" do
      pending "Punting for now.... this is going to be hard to test....."
    end
  end

end
