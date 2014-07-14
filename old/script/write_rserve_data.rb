#!/usr/bin/env ruby

## Need to restart the RServe process if you update these values

# Need the rails environment! (See load data)
require_relative '../config/environment'


##################
# HELPER METHODS #
##################

def array_to_r_vector(ary)
  numbers = true if Float(ary.first) rescue false
  if numbers
    ary.map! do |el|
      "%.15f" % el # R can't handle scentific notation automatically (e.g. 1.0e-5)
    end

    %Q{c(#{ary.join(',')})}
  else
    %Q{c("#{ary.join('","')}")}
  end
end

def output_to_vector(var_name, array)
  "#{var_name} <- #{array_to_r_vector array}"
end


#############
# LOAD DATA #
#############

implied_returns     = Security.all.select(:ticker, :implied_return).inject({}) { |h, security| h[security.ticker] = security.implied_return.to_f; h }
historical_returns  = Finance::ReturnData.values.inject({}) { |h, (ticker, vector_returns)| h[ticker] = vector_returns.to_a; h }
real_risk_free_rate = Finance::ReversePortfolioOptimization::REAL_WEEKLY_RISKLESS_RATE.to_f


##################
# PRINT COMMANDS #
##################

puts <<-EOF
## A ruby script will auto-create this entire file with the requisite data.
## `script/write_rserve_data.rb`
## You will need to do this anytime the seeded security data is updated.
## Need to restart the RServe process to take any changes into account
## # See TODO.md in rails app for thoughts around setting maximum weight per security (Constraints variable below)

## REQUIRE PACKAGES ##

pkgs <- c('timeSeries', 'fPortfolio')
cat("Loading packages...\\n")
for (pkg in pkgs) cat(pkg, ": ",require(pkg, quietly=TRUE, character.only=TRUE),"\\n",sep='')

EOF
# note extra backslash on \\n... have to escape when printing from ruby

puts output_to_vector( "all_implied_returns",        implied_returns.values )
puts output_to_vector( "all_implied_returns_names",  implied_returns.keys.map(&:to_s) )
puts "names(all_implied_returns) = all_implied_returns_names"

puts "rfr <- #{real_risk_free_rate}"
puts "no_points <- 25"

historical_returns.each_pair do |ticker, returns_array|
  puts output_to_vector ticker.to_s, returns_array.map(&:to_f)
end

puts <<-EOF

## CUSTOM FUNCTIONS ##

## Apply Forec function:
## Force a return series to have a forecasted mean (and the option of
## the forecasted variance)
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
}


## SET UP fPORTFOIO ##


Constraints <- c("LongOnly");
Spec = portfolioSpec();
setRiskFreeRate(Spec) = rfr;
setEstimator(Spec) = 'covMcdEstimator';
setNFrontierPoints(Spec) = no_points;
EOF


# tickers = ["EWC", "GSG", "VDMIX"]
# puts "\n\n****************\nRUN COMMANDS\n*****************\n\n"
# puts "Hardcoding tickers to: #{tickers}"

# # Creates a data frame with the following form:
# # return_data=data.frame(ewc=EWC,vfinx=VFINX,naesx=NAESX....)
# # Data frame is converted to a timeseries for use in fPortfolio
# data_frame_construction = "return_data = data.frame("
# data_frame_construction << (tickers.map { |ticker| "#{ticker.downcase}=#{ticker}" }).join(",")
# data_frame_construction << ")"

# # Only want a subset of the implied returns
# subset_construction = %Q{ implied_returns <- all_implied_returns[#{array_to_r_vector(tickers)}] }

# ## Execute R command and retreive value ##
# run_command = <<-EOF
#   #{subset_construction};
#   #{data_frame_construction};
#   Data = as.timeSeries(return_data);
#   forced_return_data = forec(Data, implied_returns);
#   frontier = portfolioFrontier(forced_return_data, Spec, Constraints);
#   weights = frontier@portfolio@portfolio[['weights']]
# EOF

# puts run_command
