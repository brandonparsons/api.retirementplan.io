require 'spec_helper'

describe Finance::ReversePortfolioOptimization do

  # This is pretty dirty stubbing. But you basically need to overwrite all of the
  # data with old stuff to ensure the algorithm is working correctly (was tested
  # extensively in 2012 on Google Docs).
  it 'gives the same answers as original spreadsheet, given the same inputs' do
    mod = Finance::ReversePortfolioOptimization

    mod.send(:remove_const, :LONG_TERM_INFLATION) if mod.const_defined?(:LONG_TERM_INFLATION)
    mod.const_set(:LONG_TERM_INFLATION, 0.0119)

    mod.send(:remove_const, :REAL_ANNUAL_RISKLESS_RATE) if mod.const_defined?(:REAL_ANNUAL_RISKLESS_RATE)
    mod.const_set(:REAL_ANNUAL_RISKLESS_RATE, -0.00286589583951)

    mod.send(:remove_const, :REAL_WEEKLY_RISKLESS_RATE) if mod.const_defined?(:REAL_WEEKLY_RISKLESS_RATE)
    mod.const_set(:REAL_WEEKLY_RISKLESS_RATE, -0.00005519098427)

    mod.send(:remove_const, :ANNUAL_MARKET_RISK_PREMIUM) if mod.const_defined?(:ANNUAL_MARKET_RISK_PREMIUM)
    mod.const_set(:ANNUAL_MARKET_RISK_PREMIUM, 0.0611)

    mod.send(:remove_const, :WEEKLY_MARKET_RISK_PREMIUM) if mod.const_defined?(:WEEKLY_MARKET_RISK_PREMIUM)
    mod.const_set(:WEEKLY_MARKET_RISK_PREMIUM, 0.0011)

    Finance::ReturnData.stub(:returns_file).and_return("#{Rails.root}/spec/support/old_return_data.yml")
    TBill.stub(:returns).and_return(YAML.load(File.read "#{Rails.root}/spec/support/old_tbill_data.yml").map(&:to_d))
    Finance::MarketPortfolioComposition.stub(:market_port_file).and_return("#{Rails.root}/spec/support/old_market_port_data.yml")

    calculated = mod.perform
    expected = {
      "EWC"   =>  0.0021502507,
      "VFINX" =>  0.0015936378,
      "NAESX" =>  0.0020222355,
      "VDMIX" =>  0.0019029945,
      "VFISX" =>  0.0005299824,
      "VFITX" =>  -0.0001249128,
      "VUSTX" =>  -0.0003932040,
      "EEM"   =>  0.0023298263,
      "XRE"   =>  0.0019989374,
      "XSB"   =>  0.0007320149,
      "XLB"   =>  0.0019761177,
      "BWX"   =>  0.0005291544,
      "IYR"   =>  0.0020723409,
      "RWX"   =>  0.0021338060,
      "GSG"   =>  0.0013988024,
      "CSJ"   =>  0.0001135813,
      "CIU"   =>  0.0001022847,
      "LQD"   =>  0.0001378309
    }

    expected.each_pair do |ticker, implied_return|
      expect(calculated[ticker]).to be_within(0.0001).of(implied_return)
    end

  end

end
