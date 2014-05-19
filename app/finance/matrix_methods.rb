# require 'matrix'
# require 'statsample'
# require 'statistics2'

module Finance
  module MatrixMethods

    extend self

    # @param {Returns Hash} returns_hash: This is a hash with keys being the
    # tickers, and the values being an array of returns.
    def covariance(returns_hash)
      vectors = returns_hash.inject({}) do |h, (ticker, returns)|
        h[ticker] = returns.to_scale
        h
      end
      dataset = vectors.to_dataset
      Statsample::Bivariate.covariance_matrix(dataset)
    end

    # @param {Returns Hash} returns_hash: This is a hash with keys being the
    # tickers, and the values being an array of returns.
    def correlation(returns_hash)
      vectors = returns_hash.inject({}) do |h, (ticker, returns)|
        h[ticker] = returns.to_scale
        h
      end
      dataset = vectors.to_dataset
      Statsample::Bivariate.correlation_matrix(dataset)
    end

    def cholesky_decomposition(matrix)
      # Cholesky Decomposition algorithm
      # http://www.approximity.com/public/download/code.html
      # version 0.01
      # (C) 2003 by Approximity GmbH
      # BSD-license applies

      # [BKP]: Someone in their brilliant wisdom decided to make Ruby matricies
      # immutable. We're going to send to private methods open to allow m[i][j] = x

      # [BKP]: Expecting a matrix, not an array of arrays. If you got array,
      # convert it over.
      if matrix.is_a?(Array)
        matrix = Matrix.build(matrix.length) { |row, col| matrix[row][col] }
      end

      # [BKP]: If you send in bigdecimals, this takes forever
      matrix = matrix.map(&:to_f)

      # [BKP]: Check for square property (original code assumed)
      raise 'Must be square matrix' unless matrix.square?

      n = matrix.row_size
      l = Matrix.identity(n)

      for i in ( 0 .. (n-1) )
        lsum = 0.0
        for k in ( 0 .. (i-1) )
          lsum += l[i,k] * l[i,k]
        end

        # [BKP]: Put a check in here, in case the matrix called was not positive
        # definite.
        value = matrix.row(i)[i] - lsum
        raise 'Must be a positive definite matrix' unless value > 0

        l.send :[]=, i, i, Math.sqrt(value) ## ** See note above
        # l[i][i] = Math.sqrt(value)

        for j in ( (i+1) .. (n-1) )
          lsum = 0.0
          for k in ( 0 .. (i-1) )
            lsum += l[j,k] * l[i,k]
          end
          l.send :[]=, j, i, (matrix.row(j)[i] - lsum) / l[i,i] ## ** See note above
          # l[j][i] = (matrix.row(j)[i] - lsum) / l[i,i]
        end
      end

      return l
    end

  end
end
