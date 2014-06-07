class ErpRServe
  attr_reader :con

  def initialize
    puts "Remember - you must run 'R CMD Rserve --no-save' on this computer prior to using script."
    @con = Rserve::Connection.new

    puts "Installing packages."
    @con.eval %q{ install.packages(c("timeSeries", "fPortfolio"), repos='http://cran.cnr.Berkeley.edu') }
    @con.eval %q{ require(timeSeries); require(fPortfolio) }
    # @con.eval %q{ require(Matrix); require(quadprog) }

    dir =  @con.eval("getwd()").to_ruby
    puts "\n\n***********"
    puts "Connected to R via RServe."
    puts "Working in: #{dir}"
    puts "***********\n\n"

    puts "Setting forec function"
    set_forec_function
  end

  def raw_ret(command)
    @con.eval(command)
  end

  def get_r_variable(name)
    @con.eval(name).to_ruby
  end

  def set_r_variable(name, object)
    wrapper = Rserve::REXP::Wrapper.wrap(object)
    @con.assign(name, wrapper)
  end

  def evaluate_statement(statement)
    @con.eval(statement)
  end

  # Input e.g. : historical[:NAESX]
  # Returns c(-0.004017496859423,-0.047055392415875,0.023836209205065, ..... , 0.00005551)
  def array_to_r_vector(array, options = {})
    options = {:string_vals => false}.merge(options)
    str = "c("

    if options[:string_vals]
      array.each {|ret| str << '\'' << ret.to_s << '\'' << ","}
    else
      array.each {|ret| str << ret.to_s << ","}
    end

    str.chomp!(",")
    str << ")"
  end

  # Sets a vector inside R with named colums.
  # Pulling vector to ruby (i.e. get_r_variable) will simply return the values
  # (names are lost).
  def set_vector_with_names_via_hash(r_var_name, hash)
    vals = array_to_r_vector(hash.values)
    nms = array_to_r_vector(hash.keys, :string_vals => true)

    command = "#{r_var_name} <- #{vals}; names(#{r_var_name}) = #{nms}"
    @con.eval(command)
  end

  def set_forec_function
    # Set up the "forec" function - forces a set of returns to have a specified
    # mean without affecting the covariances (used to hack fPortfolio covariance
    # estimator functions).

    # Want this because the historical return data will not have the same mean
    # return as the 'implied returns' we are calculating through Reverse
    # Portfolio Optimization. So adjust the returns in R to the implied values,
    # but keep the same behaviour between securities (covariances).
    str = <<-EOF
      ## Force a return series to have a forecasted mean (and the option of the forecasted variance)
      forec=function(x,estRet,estSD=NULL) {
        if (length(estRet)!=ncol(x)) stop("Forecast columns do not match up with data")
        if(!is.null(estSD)) {
          # Set the new asset returns to have the target volatility
          sdx <- apply(x,2,sd)
          newx=sweep(x,2, estSD/sdx, "*")
          # Set the new asset returns to have the target mean
          newx=sweep(newx, 2, colMeans(newx) - estRet, "-")
        } else {
          newx=sweep(x, 2, colMeans(x) - estRet, "-")
        }
        return(newx)

      } # END
    EOF
    @con.eval(str)
  end

  # Preparation to create the historical returns dataframe
  # Creates R vectors for each ticker - vector is returns
  # e.g. 'LQD <- c(0.001,0.002,-0.003)'
  def set_r_vectors_for_all_tickers(historical_returns_hash)
    historical_returns_hash.each_pair do |key, value|
      if key == :DATE
        ary = value.map {|d| d.strftime('%d %b %Y')}
        vec = array_to_r_vector(ary, string_vals: true)
      else
        vec = array_to_r_vector(value)
      end

      command = "#{key.to_s} <- #{vec}"
      @con.eval(command)
    end
  end

  # Creates a data frame with the following form:
  # return_data=data.frame(date=DATE,ewc=EWC,vfinx=VFINX,naesx=NAESX....)
  # Data frame is converted to a timeseries for use in fPortfolio
  def create_data_frame_for_returns(column_names_array)
    command = "return_data=data.frame("

    column_names_array.each {|name| command << "#{name.downcase}=#{name},"}

    command.chomp!(",")
    command << ")"

    @con.eval("#{command};Data = as.timeSeries(return_data)")
  end

  # Completes the efficient frontier optimization, and pulls the relevant data
  # out of the R object structure.
  # R returns as a matrix - convert to a more usable object (array of arrays)
  # Can access individual portfolios as return_variable[1]
  def run_efficient_frontier(real_risk_free_rate)

    # Grab the names and number of securities:
    names = @con.eval("names(Data)").to_ruby
    no_of_securities = names.size

    constraints_command = %q{Constraints <- c("LongOnly")}
    # You can't do "LongOnly", and specify weights. Have to do a minW[1:18]=0.0
    # %q{<- c("minW[1:nAssets]=0", "maxsumW[1:2Assets]=13.63")}
    # "maxW[1:18]=0.9"
    # "Constraints <- c('maxW[1:#{no_of_securities}] = rep( 0.9, times = #{no_of_securities})')"
    # Constraints = "minW=c(0.74,0,0,0)"  #### this is a long -only

    frontier_points = 20

    @con.eval("forced_return_data = forec(Data, implied_returns);#{constraints_command};Spec = portfolioSpec();setRiskFreeRate(Spec) = #{real_risk_free_rate};setEstimator(Spec) = 'covMcdEstimator';setNFrontierPoints(Spec) = #{frontier_points};frontier = portfolioFrontier(forced_return_data, Spec, Constraints);weights = frontier@portfolio@portfolio[['weights']]")
    weights = get_r_variable("weights")

    if weights.respond_to?(:row_vectors)
      # For some reason, you sometimes get a matrix, and others just a plain array
      vectors = weights.row_vectors
    else
      vectors = [weights]
    end

    # Grab the list of variable names to make the return thing into a useful
    # hash. Do it from the R variable in case the order changed for some reason
    # from the ruby ones.
    vectors.map! {|vector| vector.to_a}
    portfolio_weights = []
    vectors.each do |weights_set|
      hash = {}
      weights_set.each_with_index do |weight, index|
        hash[names[index].upcase.to_sym] = weight
      end
      portfolio_weights << hash
    end

    return portfolio_weights
  end

  def get_efficient_frontiers(real_risk_free_rate, implied_expected_returns, historical_returns)
    set_vector_with_names_via_hash("implied_returns", implied_expected_returns)
    set_r_vectors_for_all_tickers(historical_returns)
    create_data_frame_for_returns(historical_returns.keys)
    return run_efficient_frontier(real_risk_free_rate)
  end

end
