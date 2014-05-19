# require 'statsample'
# require 'statistics2'

module Finance
  module Statistics

    extend self

    def mean(array)
      array.to_scale.mean
    end

    def standard_deviation(array)
      array.to_scale.sd
    end

    def mean_and_standard_deviation(array)
      scaled = array.to_scale
      return scaled.mean, scaled.sd
    end

    def portfolio_monthly_return_for(investment, annual_return)
      (investment * ( (1 + annual_return).to_f ** (1.0/12)  - 1 ))
    end

    def portfolio_daily_var_for(investment, annual_return, annual_std_dev)
      (-1 * investment * ( annual_return/250 + (-1.65 * annual_std_dev/Math.sqrt(250)) ) ).round(2)
    end

  end
end
