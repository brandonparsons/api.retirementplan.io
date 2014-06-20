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

  end
end
