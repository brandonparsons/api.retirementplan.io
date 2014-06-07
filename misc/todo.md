TODO: RetirementPlan.io - Rails App
===================================

- Actually test delivered emails (not just that jobs get put onto queue)

- Checkbox in portfolio selection & simulation page (or in user profile?) that swaps between using implied return and historical mean return


- REfficientFrontier: instead of only specifying 'longOnly', could set a maximum weight in each security...
## NOT WORKING YET ##
# no_of_securities = tickers.size
# You can't do "LongOnly", and specify weights. Have to do a minW[1:18]=0.0
# %q{<- c("minW[1:nAssets]=0", "maxsumW[1:2Assets]=13.63")}
# "maxW[1:18]=0.9"
# "Constraints <- c('maxW[1:#{no_of_securities}] = rep( 0.9, times = #{no_of_securities})')"
# Constraints = "minW=c(0.74,0,0,0)"  #### this is a long -only


- statsample-optimization gem. Need to have GSL etc. on the comp
