require 'spec_helper'

def build_basic_portfolio
  s1 = create(:security, :bwx)
  s2 = create(:security, :eem)
  s3 = create(:security, :vdmix)

  p = Portfolio.create(weights: {
    "BWX"   => 0.30,
    "EEM"   => 0.35,
    "VDMIX" => 0.35
  })

  p.selected_etfs = {
    "BWX"   => "BWZ",
    "EEM"   => "SCHE",
    "VDMIX" => "VDMIX"
  }

  p.current_shares = {
    "BWZ"   => 300,
    "SCHE"  => 350,
    "VDMIX" => 350
  }

  p.save
  return p
end

describe Portfolio do

  it "is valid from factory" do
    p = build(:portfolio)
    p.valid?.should be_true
  end

  describe "statistics" do
    before(:each) do
      @s1 = create(:security, :vdmix,  returns: [0.08, -0.06, 0.10, 0.03, 0.10])
      @s2 = create(:security, :bwx,    returns: [0.01, 0.04, -0.03, 0.08, 0.02])
      @s3 = create(:security, :eem,    returns: [0.12, -0.32, 0.18, 0.03, 0.10])
      u = build_stubbed(:user)
      @p  = Portfolio.create! weights: { "VDMIX" => 0.3, "BWX" => 0.4, "EEM" => 0.3 }, user_id: u.id
    end

    it "sets correct portfolio expected mean return" do
      # Mean return is based on implied_return by default
      expect(@p.expected_return).to be_within(0.001).of(0.0425)
    end

    it "sets correct portfolio expected std dev" do
      expect(@p.expected_std_dev).to be_within(0.005).of(0.0726993810152466)
    end
  end

  describe "weights" do
    before(:each) do
      @s1 = create(:security, :bwx)
      @s2 = create(:security, :eem)
      @u  = build_stubbed(:user)
    end

    it "can retreieve weights" do
      p = Portfolio.create! user_id: @u.id, weights: {"EEM" => 0.4, "BWX" => 0.6}
      expect(p.weights).to eql({"BWX" => 0.6, "EEM" => 0.4})
    end

    it "doesn't allow malformed weights" do
      p = Portfolio.new user_id: @u.id, weights: {"EEM" => "abc", "BWX" => 0.4}
      p.should_not be_valid
    end

    it "now allows duplicate weights (because creating separate portfolios for each user)" do
      Portfolio.create! user_id: @u.id, weights: {"EEM" => 0.4, "BWX" => 0.6}
      p = Portfolio.new user_id: build_stubbed(:user).id, weights: {"EEM" => 0.4, "BWX" => 0.6}
      p.should be_valid
    end

    it "saves as upcased weights" do
      p = Portfolio.create! user_id: @u.id, weights: {"EEM" => 0.4, "bwx" => 0.6}
      p.weights.should include("BWX")
    end

    it "saves as alphabetical weights" do
      p = Portfolio.create! user_id: @u.id, weights: {"EEM" => 0.4, "bwx" => 0.6}
      expect(p.weights).to eql({"BWX" => 0.6, "EEM" => 0.4})
    end

    it "doesn't allow weights if dont sum to 100%" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 0.6, "EEM" => 0.3}
      p.should_not be_valid
    end

    it "doesn't allow weights if dont sum to 100%" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 0.6, "EEM" => 0.6}
      p.should_not be_valid
    end

    it "fixes weights if small error due to float math" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 1.0001}
      p.should be_valid
    end

    it "allows slight errors in sum" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 0.6, "EEM" => 0.40001}
      p.should be_valid
    end

    it "doesn't allow weight < 0.0" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 0.6, "EEM" => -0.1}
      p.should_not be_valid
    end

    it "doesnt allow weight > 1.0" do
      p = Portfolio.new user_id: @u.id, weights: {"BWX" => 0.6, "EEM" => 1.001}
      p.should_not be_valid
    end
  end

  describe "selected_etfs" do
    it 'confirms that all selected securities match with the selected_portfolio' do
      u = build_stubbed(:user)
      p = create(:portfolio, user: u)

      p.should be_valid

      p.selected_etfs = {
        "BWX"   => "BWZ",
        "EEM"   => "SCHE",
        "VDMIX" => "VDMIX"
      }

      p.should be_valid

      p.selected_etfs = p.selected_etfs.merge({"IMADETHISUP" => "BWZ"})
      p.should_not be_valid
    end
  end

  describe "hstore_accessor properties" do
    before(:each) do
      @p = build_stubbed(:portfolio)
    end

    it "responds to selected_etfs" do
      @p.should respond_to(:selected_etfs)
      @p.should respond_to(:selected_etfs=)
    end

    it "responds to current_shares" do
      @p.should respond_to(:current_shares)
      @p.should respond_to(:current_shares=)
    end

    it "responds to tracking" do
      @p.should respond_to(:tracking)
      @p.should respond_to(:tracking?)
      @p.should respond_to(:tracking=)
    end
  end

  describe "#current_allocation" do
    before(:each) do
      @p = build_basic_portfolio
    end

    it "returns the appropriate value if everything is normal" do
      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.current_allocation).to eql({
        "BWZ"   => 0.30,
        "SCHE"  => 0.35,
        "VDMIX" => 0.35
      })
    end

    it "returns zeroes if current_shares are zeroes" do
      # Was returning NaN here before, and screwing things up
      @p.current_shares = {
        "BWZ"   => 0.0,
        "SCHE"  => 0.0,
        "VDMIX" => 0.0
      }
      @p.save

      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.current_allocation).to eql({
        "BWZ"   => 0.0,
        "SCHE"   => 0.0,
        "VDMIX" => 0.0
      })
    end
  end

  describe "#out_of_balance?" do
    before(:each) do
      @p = build_basic_portfolio
    end

    it "returns false if perfectly in balance" do
      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.out_of_balance?(0.05)).to be_false
    end
    it "returns false if out of balance, within allowable drift" do
      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 105,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.out_of_balance?(0.05)).to be_false
    end
    it "returns true if out of balance, above drift" do
      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 200,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.out_of_balance?(0.05)).to be_true
    end

    it "can handle current allocation tickers being different from target weights" do
      @p.current_shares = {
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100,
        "GSG"   => 400 # Does not show up in the selected portfolio
      }

      Finance::Quotes.should_receive(:for_etfs).with(["BWZ", "SCHE", "VDMIX", "GSG"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100,
        "GSG"   => 100
      })

      expect(@p.out_of_balance?(0.05)).to be_true # First three would be in balance, but have extraneous fourth security
    end
  end

  describe "#apply_transaction" do
    before(:each) do
      @p = build_basic_portfolio
    end

    it "successfully applies transactions, with only current etfs" do
      @p.apply_transaction({
        "BWZ"   => 100,
        "SCHE"  => 0,
        "VDMIX" => -50
      })

      expect(@p.current_shares).to eql({
        "BWZ"   => 400.0,
        "SCHE"  => 350.0,
        "VDMIX" => 300.0
      })
    end

    it "successfully applies transactions, with additional etfs" do
      @p.apply_transaction({
        "BWZ"   => 100,
        "SCHE"  => 0,
        "VDMIX" => -50,
        "ZZZ"   => 100
      })

      expect(@p.current_shares).to eql({
        "BWZ"   => 400.0,
        "SCHE"  => 350.0,
        "VDMIX" => 300.0,
        "ZZZ"   => 100.0
      })
    end
  end

  describe "#rebalance" do
    before(:each) do
      @p = build_basic_portfolio
    end

    it "returns zeroes if perfectly in balance" do
      Finance::Quotes.stub(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.rebalance).to eql({
        "BWZ"   => 0,
        "SCHE"  => 0,
        "VDMIX" => 0
      })
    end

    it "returns the correct values with no additional funds" do
      Finance::Quotes.stub(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 150,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.rebalance).to eql({
        "BWZ"   => -70,
        "SCHE"  => 53,
        "VDMIX" => 53
      })
    end

    it "sells the extraneous security (outside of target allocation)" do
      @p.current_shares = {
        "BWZ"   => 300,
        "SCHE"  => 350,
        "VDMIX" => 350,
        "GSG"   => 400
      }
      @p.save

      Finance::Quotes.stub(:for_etfs).with(["BWZ", "SCHE", "VDMIX", "GSG"]).and_return({
        "BWZ"   => 100,
        "SCHE"  => 100,
        "VDMIX" => 100,
        "GSG"   => 100
      })

      expect(@p.rebalance["GSG"]).to eql(-400)
    end

    it "returns the correct values with some additional funds" do
      Finance::Quotes.stub(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 150,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.rebalance(10000)).to eql({
        "BWZ"   => -50,
        "SCHE"  => 88,
        "VDMIX" => 88
      })
    end

    it "returns the correct values for selling securities" do
      Finance::Quotes.stub(:for_etfs).with(["BWZ", "SCHE", "VDMIX"]).and_return({
        "BWZ"   => 150,
        "SCHE"  => 100,
        "VDMIX" => 100
      })

      expect(@p.rebalance(-10000)).to eql({
        "BWZ"   => -90,
        "SCHE"  => 18,
        "VDMIX" => 18
      })
    end
  end

  describe "#update_current_shares_with" do
    before(:each) do
      @p = build_basic_portfolio
    end

    it "errors if not a hash" do
      expect{@p.update_current_shares_with(["EWC", 5])}.to raise_error
    end

    it "handles an empty hash" do
      expect(@p.update_current_shares_with({})).to eql({
        "BWZ"   => 300,
        "SCHE"  => 350,
        "VDMIX" => 350
      })
    end

    it "handles an update of existing ETF" do
      @p.update_current_shares_with({
        "SCHE"  => 400,
        "VDMIX" => 0
      })

      expect(@p.current_shares).to eql({
        "BWZ"   => 300,
        "SCHE"  => 400,
        "VDMIX" => 0
      })
    end

    it "handles a brand new security" do
      @p.update_current_shares_with({
        "XLB"  => 100
      })

      expect(@p.current_shares).to eql({
        "BWZ"   => 300,
        "SCHE"  => 350,
        "VDMIX" => 350,
        "XLB"   => 100
      })
    end

    it "handles a mix of both" do
      @p.update_current_shares_with({
        "XLB"  => 100,
        "SCHE" => 400
      })

      expect(@p.current_shares).to eql({
        "BWZ"   => 300,
        "SCHE"  => 400,
        "VDMIX" => 350,
        "XLB"   => 100
      })
    end
  end

end
