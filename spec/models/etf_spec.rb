require 'spec_helper'

describe Etf do

  describe "::info_lookup_table" do
    it 'requires a set of tickers' do
      expect{ Etf.info_lookup_table([]) }.to raise_error
    end

    it "creates valid output" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)

      e1 = create(:etf, security: s1, ticker: "VDMIX1", description: "A special ETF")
      e2 = create(:etf, security: s2, ticker: "BWX1", description: "Another special ETF")

      results = Etf.info_lookup_table [e1.ticker, e2.ticker]
      expect(results).to eql({
        e1.ticker => {
          asset_class: s1.asset_class,
          description: e1.description
        },
        e2.ticker => {
          asset_class: s2.asset_class,
          description: e2.description
        }
      })
    end
  end

  describe "::security_ticker_for_etf" do
    it "returns the correct security ticker for an ETF" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)
      e1 = create(:etf, security: s1, ticker: "VDMIX1", description: "A special ETF")
      e2 = create(:etf, security: s2, ticker: "BWX1", description: "Another special ETF")

      expect(Etf.security_ticker_for_etf "BWX1").to eql("BWX")
    end

    it "returns nil if nothing" do
      expect(Etf.security_ticker_for_etf("FAKE")).to be_nil
    end
  end

  it "is valid from factory" do
    e = build(:etf)
    e.valid?.should be_true
  end

  it "normalizes data on save" do
    e = create(:etf, ticker: "aaB")
    expect(e.ticker).to eql("AAB")
  end

end
