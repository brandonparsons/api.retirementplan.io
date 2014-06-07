require 'spec_helper'

describe RetirementSimulation do

  context 'all tough work stubbed out' do
    before(:each) do
      u = build_stubbed(:user)
      r = RetirementSimulation.new(u)

      # Leave as should_receive instead of stub so you can be sure these are all
      # getting called (testing the private methods directly below).
      r.should_receive(:sorted_weights).and_return({})
      r.should_receive(:simulation_parameters).and_return({})
      r.should_receive(:expenses).and_return([])
      r.should_receive(:time_steps).and_return([])
      r.should_receive(:asset_return_data).and_return({})

      @results = r.simulation_data
    end

    it "outputs data of the correct form" do
      expect(@results).to include(:number_of_periods)
      expect(@results).to include(:selected_portfolio_weights)
      expect(@results).to include(:simulation_parameters)
      expect(@results).to include(:expenses)
      expect(@results).to include(:time_steps)
      expect(@results).to include(:real_estate)
      expect(@results).to include(:inflation)
      expect(@results).to include(:asset_return_data)
    end

    it "gets real estate and inflation values correct" do
      @results[:real_estate][:mean].should be_within(1).of(0) # +/- 1
      @results[:real_estate][:std_dev].should be_within(1).of(0) # +/- 1

      @results[:inflation][:mean].should be_within(1).of(0) # +/- 1
      @results[:inflation][:std_dev].should be_within(1).of(0) # +/- 1
    end
  end

  describe "sorted_weights" do
    it "returns sorted_weights that look right" do
      u = build_stubbed(:user)
      p = create(:portfolio, user_id: u.id)

      results = RetirementSimulation.new(u).send(:sorted_weights)
      expect(results).to eql({
        "BWX"   => p.weights["BWX"],
        "EEM"   => p.weights["EEM"],
        "VDMIX" => p.weights["VDMIX"]
      })
    end
  end

  describe "simulation_parameters" do
    it "returns serialized parameters" do
      u = create(:user)
      p = create(:retirement_simulation_parameters, user: u)

      results = RetirementSimulation.new(u).send(:simulation_parameters)

      expect(results).to include(:married)
      expect(results).to include(:user_is_male)
    end
  end

  describe "expenses" do
    it "returns serialized expenses, only added" do
      u   = create(:user)
      e1  = create(:expense)
      e2  = create(:expense, :added, description: "Food", user: u)

      results = RetirementSimulation.new(u).send(:expenses)

      expect(results.length).to eql(1)
      expect(results.first).to include(:amount)
      expect(results.first).to include(:frequency)
    end
  end

  describe "time_steps" do
    it "returns a full set of time steps, tailored to ages" do
      u = create(:user)
      p = create(:retirement_simulation_parameters, user: u, male_age: 34, female_age: 36)

      results = RetirementSimulation.new(u).send(:time_steps)

      expect(results).to include(:weekly)
      expect(results).to include(:monthly)
      expect(results).to include(:annual)

      expect(results[:weekly]).to be_a(Array)
      expect(results[:monthly]).to be_a(Array)
      expect(results[:annual]).to be_a(Array)

      expect(results[:weekly].length).to eql(4472)
      expect(results[:monthly].length).to eql(1032)
      expect(results[:annual].length).to eql(86)
    end
  end

  describe "asset_return_data" do
    it "returns a correctly formed set of information" do
      s1 = create(:security, :bwx)
      s2 = create(:security, :eem)
      s3 = create(:security, :vdmix)

      u = create(:user)

      # Correlation and cholesky methods already tested elsewhere. Does not play
      # well with factory-built securities.
      Finance::MatrixMethods.should_receive(:correlation).and_return([[1,2], [3,4]])
      Finance::MatrixMethods.should_receive(:cholesky_decomposition).and_return([[1,2], [3,4]])

      results = RetirementSimulation.new(u).send(:asset_return_data)

      expect(results[:tickers]).to eql(["BWX", "EEM", "VDMIX"])

      expect(results[:mean_returns].length).to eql(3)
      expect(results[:mean_returns].first).to be_within(1).of(0)

      expect(results[:std_devs].length).to eql(3)
      expect(results[:std_devs].first).to be_within(1).of(0)

      expect(results[:c_d]).to eql([[1,2], [3,4]])
    end
  end

end
