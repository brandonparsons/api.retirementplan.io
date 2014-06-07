require 'spec_helper'
require 'matrix'

def equal_matrix(m1, m2)
  rows = m1.row_size
  (0...rows).each do |row_index|
    m1.row(row_index).each_with_index do |val, col_index|
      m2[row_index, col_index].should be_within(0.01).of(val)
    end
  end
end

describe Finance::MatrixMethods do

  describe "::covariance" do
    it "can calculate a correct covariance matrix" do
      returns_hash = {
        "GOOG" => [0.08, 0.10, -0.06, -0.09, 0.11],
        "APPL" => [0.06, 0.05, 0.03, 0.08, -0.01],
        "XOM" =>  [0.07, 0.08, 0.06, 0.05, 0.02]
      }

      answer = Finance::MatrixMethods.covariance(returns_hash)
      correct = Matrix[
        [0.007256, -0.001236, -0.0000279999999999996],
        [-0.001236, 0.000936, 0.000408],
        [-0.0000279999999999996, 0.000408, 0.000424]
      ] # Calculated using Mac OSX Numbers

      equal_matrix(answer, correct)
    end
  end # covariance


  describe "::correlation" do
    it "can correctly calculate a correlation matrix" do
      returns_hash = {
        "AAA" => [ 0.08, 0.04, 0.11, 0.01 ],
        "BBB" => [-0.04, 0.15, 0.10, -0.03],
        "CCC" => [0.0, 0.01, 0.02, 0.01]
      }

      answer = Finance::MatrixMethods.correlation(returns_hash)
      correct = Matrix[
        [1.000, 0.216159151725073, 0.278543007265578],
        [0.216159151725073, 1.0, 0.603582858982918],
        [0.278543007265578, 0.603582858982918, 1.0]
      ]

      equal_matrix(answer, correct)
    end

    it "gives the same answers as MDArray" do
      hsh = {
        "AAA"=>[0.01, 0.04, 0.06, -0.12, -0.04],
        "BBB"=>[-0.03, 0.01, 0.02, 0.0, -0.01],
        "CCC"=>[0.12, 0.15, -0.28, 0.04, 0.18]
      }

      answer  = Finance::MatrixMethods.correlation(hsh)
      correct = Matrix[[1.0, 0.28837490036423624, -0.3607411576211152], [0.28837490036423624, 0.9999999999999998, -0.6297203694048776], [-0.36074115762111525, -0.6297203694048777, 0.9999999999999999]]
      equal_matrix(answer, correct)
    end
  end


  describe "::cholesky_decomposition" do

    it "Can correctly perform a cholesky decomposition" do
      t = Matrix[ [4,12,-16],
                  [12,37,-43],
                  [-16,-43,98] ]
      answer = Finance::MatrixMethods.cholesky_decomposition(t)

      tcorrect = Matrix[[2.0, 0, 0], [6.0, 1.0, 0], [-8.0, 5.0, 3.0]]
      equal_matrix(answer, tcorrect)
    end

    it "Can correctly perform a cholesky decomposition" do
      t = Matrix[ [1.0    , 1.0/2.0, 1.0/3.0, 1.0/4.0],
                [1.0/2.0, 1.0/3.0, 1.0/4.0, 1.0/5.0 ],
                [1.0/3.0, 1.0/4.0, 1.0/5.0, 1.0/6.0 ],
                [1.0/4.0, 1.0/5.0, 1.0/6.0, 1.0/7.0 ]]

      answer = Finance::MatrixMethods.cholesky_decomposition(t)

      tcorrect = Matrix[[1.0, 0.0, 0.0, 0.0],
                        [0.5, 0.288675, 0.0, 0.0],
                        [0.333333, 0.288675, 0.0745356, 0.0],
                        [0.25, 0.259808, 0.111803, 0.0188982]]

      equal_matrix(answer, tcorrect)
    end

    it "Can correctly perform a cholesky decomposition" do
      t = Matrix[ [1.0, 0.0, 0.0],
                  [0.0, 2.0, 0.0],
                  [0.0, 0.0, 3.0]]
      answer = Finance::MatrixMethods.cholesky_decomposition(t)

      tcorrect = Matrix[[1.0, 0.0, 0.0],
                        [0.0, 1.414, 0.0],
                        [0.0, 0.0, 1.732]]

      equal_matrix(answer, tcorrect)
    end

    it "gives the same answers as MDArray" do
      hsh = {
        "AAA" =>  [0.01, 0.04, 0.06, -0.12, -0.04],
        "BBB" =>  [-0.03, 0.01, 0.02, 0.0, -0.01],
        "CCC" =>  [0.12, 0.15, -0.28, 0.04, 0.18]
      }

      answer  = Finance::MatrixMethods.cholesky_decomposition(Finance::MatrixMethods.correlation(hsh))
      correct = Matrix[[1.0, 0.0, 0.0], [0.28837490036423624, 0.9575175804338616, 0.0], [-0.3607411576211152, -0.5490151666775797, 0.7539550145440821]]
      equal_matrix(answer, correct)
    end
  end # cholesky

end
