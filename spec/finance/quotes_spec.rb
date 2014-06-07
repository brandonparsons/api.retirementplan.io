require 'spec_helper'

describe Finance::Quotes do

  # This test will fail if offline!
  # Could bring in VCR,  but will test against live API for now.
  it "[FAILS IF OFFLINE] returns quote data for all etfs" do
    e1 = create(:etf, :xlb)
    e1 = create(:etf, :dbc)
    e1 = create(:etf, :gsg)
    e1 = create(:etf, :usci)

    results = Finance::Quotes.send(:all_etfs)

    expect(results.length).to eql(4)
    expect(results.keys).to eql([
      "DBC",
      "GSG",
      "USCI",
      "XLB"
    ])
    expect(results["GSG"]).to be < 3000 # Price could be anything, but this should work
  end

  it "returns empty array if no tickers requested" do
    results = Finance::Quotes.for_etfs([])
    expect(results).to eql([])
  end

  it "raises an error if not passed an array" do
    expect { Finance::Quotes.for_etfs( "BWX" ) }.to raise_error
  end

  it "returns only data on the specific tickers when requested" do
    Finance::Quotes.stub(:all_etfs).and_return({
      "BWX"   => 100,
      "EEM"   => 100,
      "NAESX" => 100,
      "VDMIX" => 100
    })

    results = Finance::Quotes.for_etfs(["EEM", "NAESX"])
    expect(results).to eql({
      "EEM"   => 100,
      "NAESX" => 100
    })
  end

end
