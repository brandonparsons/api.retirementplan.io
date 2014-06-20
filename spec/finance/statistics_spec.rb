require 'spec_helper'

describe Finance::Statistics do

  specify "::mean" do
    vals = [0.08, 0.09, -0.10, 0.0, 0.12]
    calculated_mean = Finance::Statistics.mean(vals)
    expect(calculated_mean).to be_within(0.0001).of(0.038)
  end

  specify "::standard_deviation" do
    vals = [0.08, 0.09, -0.10, 0.0, 0.12]
    calculated_stdev = Finance::Statistics.standard_deviation(vals)
    expect(calculated_stdev).to be_within(0.0001).of(0.088994381845148)
  end

  specify "::mean_and_standard_deviation" do
    vals = [0.08, 0.09, -0.10, 0.0, 0.12]
    calculated_mean, calculated_stdev = Finance::Statistics.mean_and_standard_deviation(vals)
    expect(calculated_mean).to be_within(0.0001).of(0.038)
    expect(calculated_stdev).to be_within(0.0001).of(0.088994381845148)
  end

end
