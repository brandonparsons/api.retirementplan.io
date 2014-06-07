require 'spec_helper'

describe RealEstate do

  specify "::values" do
    # This tests that the repo has the yml file, in the correct format
    vals = RealEstate.values
    vals.is_a?(Array).should be_true
    vals.first.is_a?(BigDecimal).should be_true
  end

  specify "::mean" do
    # Values from the web are quarterly - RE converts these to monthly
    RealEstate.stub(:values).and_return([0.1, 0.2, 0.3])
    expect(RealEstate.mean).to be_within(0.01).of(0.062658569)
  end

  specify "::std_dev" do
    # Values from the web are quarterly - RE converts these to monthly
    RealEstate.stub(:values).and_return([0.1, 0.2, 0.3])
    RealEstate.stub(:mean).and_return(0.062658569)
    expect(RealEstate.std_dev).to be_within(0.01).of(0.0577350266302874)
  end

end
