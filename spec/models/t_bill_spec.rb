require 'spec_helper'

describe TBill do

  specify "::returns" do
    # This tests that the repo has the yml file, in the correct format
    rets = TBill.returns
    rets.is_a?(Array).should be_true
    rets.first.is_a?(BigDecimal).should be_true
  end

  specify "::mean" do
    TBill.stub(:returns).and_return([0.1, 0.2, 0.3])
    expect(TBill.mean).to be_within(0.01).of(0.2)
  end

  specify "::std_dev" do
    TBill.stub(:returns).and_return([0.1, 0.2, 0.3])
    expect(TBill.std_dev).to be_within(0.01).of(0.1)
  end

end
