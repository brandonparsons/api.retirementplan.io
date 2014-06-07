require 'spec_helper'

describe Security do

  it "is valid from factory" do
    s = build(:security)
    s.valid?.should be_true
  end

  it "normalizes data on save" do
    s = create(:security, ticker: "aaB")
    expect(s.ticker).to eql("AAB")
  end

  it "sets its own statistics" do
    s = create(:security, returns: [0.04, 0.06, 0.10])
    expect(s.mean_return).to be_within(0.0001).of(0.0666666666666667)
    expect(s.std_dev).to be_within(0.0001).of(0.0305)
  end

  it "must be of valid class" do
    s = build(:security, asset_class: "crazy")
    s.valid?.should be_false
  end

  it "must be valid asset type" do
    s = build(:security, asset_type: "crazy")
    s.valid?.should be_false
  end

  describe "::all_tickers" do
    it "needs tests" do
      pending
    end
  end

  describe "::asset_class_for_ticker" do
    it "returns the correct asset class for an existing ticker" do
      s = create(:security)
      expect(Security.asset_class_for_ticker s.ticker).to eql(s.asset_class)
    end

    it 'returns nil for invalid ticker' do
      expect(Security.asset_class_for_ticker "asbdkfj").to be_nil
    end
  end

  describe "::available_asset_classes" do
    it 'returns list of asset classes' do
      create(:security, :vdmix)
      create(:security, :bwx)
      create(:security, :eem)
      expect(Security.available_asset_classes).to eql({"Canadian Long-term Bonds"=>"VDMIX", "Emerging Markets Equities"=>"EEM", "International Bonds"=>"BWX"})
    end

    it "doesn't include asset classes if in $DISABLED_SECURITIES list" do
      orig_disabled_securities = $DISABLED_SECURITIES
      $DISABLED_SECURITIES = ['VDMIX']
      create(:security, :vdmix)
      create(:security, :bwx)
      create(:security, :eem)
      expect(Security.available_asset_classes).to eql({"Emerging Markets Equities"=>"EEM", "International Bonds"=>"BWX"})
      $DISABLED_SECURITIES = orig_disabled_securities
    end
  end

  describe "::last_updated_time" do
    it "returns the correct record" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)
      s3 = create(:security, :eem)

      s1.update_attributes!(implied_return: 0.11)
      expect(Security.last_updated_time).to eql(s1.updated_at.utc.to_i)

      s3.update_attributes!(implied_return: 0.12)
      expect(Security.last_updated_time).to eql(s3.updated_at.utc.to_i)
    end
  end

  describe "::statistics_for_all" do
    it "returns the correct values for :implied_return" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)

      results = Security.statistics_for_all :implied_return

      results.first.should include :ticker
      results.first.should include :mean_return
      results.first.should include :std_dev
      results.first.should include :returns

      expect(results.first[:ticker]).to eql("BWX")
      expect(results.first[:mean_return].to_f).to eql(0.011)
      expect(results.first[:std_dev].to_f).to be_within(0.01).of(0.04509)
      expect(results.first[:returns]).to eql([0.01, 0.05, -0.04])

      expect(results.last[:ticker]).to eql("VDMIX")
    end

    it "returns the correct values for :mean_return" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)

      results = Security.statistics_for_all :mean_return

      results.first.should include :ticker
      results.first.should include :mean_return
      results.first.should include :std_dev
      results.first.should include :returns

      expect(results.first[:ticker]).to eql("BWX")
      expect(results.first[:mean_return].to_f).to be_within(0.001).of(0.006666667)
      expect(results.first[:std_dev].to_f).to be_within(0.01).of(0.04509)
      expect(results.first[:returns]).to eql([0.01, 0.05, -0.04])

      expect(results.last[:ticker]).to eql("VDMIX")
    end
  end

  describe "::statistics_for" do
    it "only returns the tickers requested" do
      s1 = create(:security, :vdmix)
      s2 = create(:security, :bwx)

      results = Security.statistics_for ["VDMIX"], :implied_return

      expect(results.length).to eql(1)

      results.first.should include :ticker
      results.first.should include :mean_return
      results.first.should include :std_dev
      results.first.should include :returns

      expect(results.first[:ticker]).to eql("VDMIX")
    end

    it "returns empty array if no tickers" do
      expect(Security.statistics_for [], :implied_return).to eql([])
    end

    it "requires an array to be passed" do
      expect{Security.statistics_for "VDMIX", :implied_return}.to raise_error
    end
  end

end
