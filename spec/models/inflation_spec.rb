require 'spec_helper'

describe Inflation do

  specify "::values" do
    # This tests that the repo has the yml file, in the correct format
    vals = Inflation.values
    vals.is_a?(Array).should be_true
    vals.first.is_a?(BigDecimal).should be_true
  end

  specify "::mean" do
    Inflation.stub(:values).and_return([0.1, 0.2, 0.3])
    expect(Inflation.mean).to be_within(0.01).of(0.2)
  end

  specify "::std_dev" do
    Inflation.stub(:values).and_return([0.1, 0.2, 0.3])
    expect(Inflation.std_dev).to be_within(0.01).of(0.1)
  end

end
