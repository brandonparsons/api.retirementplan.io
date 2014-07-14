# gem 'recurrence' # Calculates timelines/schedules

class RetirementSimulationDataService

  #################
  # CLASS METHODS #
  #################

  def self.warm_cache
    empty_instance = new({})
    empty_instance.send(:build_schedules)
    empty_instance.send(:asset_return_data)
  end


  ####################
  # INSTANCE METHODS #
  ####################

  def initialize(user)
    @user = user
  end

  # FIXME: Is this required after going to Ember / Go sim?
  def simulation_data(number_of_periods=1440)
    # Key names depended on by Javascript

    return {
      number_of_periods:          number_of_periods,
      selected_portfolio_weights: sorted_weights,
      simulation_parameters:      simulation_input,
      expenses:                   expenses,
      time_steps:                 time_steps,
      real_estate: {
        mean:     RealEstate.mean,
        std_dev:  RealEstate.std_dev
      },
      inflation: {
        mean:     Inflation.mean,
        std_dev:  Inflation.std_dev
      },
      asset_return_data: asset_return_data
    }
  end


  private

  ## Basically all of these private methods have been stubbed throughout the spec
  ## for this class. Careful.

  def sorted_weights
    selected_portfolio_weights  = @user.portfolio.weights
    sorted_weights              = {}
    selected_portfolio_weights.keys.sort.each do |k|
      sorted_weights[k] = selected_portfolio_weights[k]
    end

    return sorted_weights
  end

  def simulation_input
    SimulationInputSerializer.new(@user.simulation_input).as_json(root: false)
  end

  def expenses
    ActiveModel::ArraySerializer.new(@user.expenses.where(is_added: true), each_serializer: ExpenseSerializer, root: false).as_json
  end

  def time_steps
    full_weekly_schedule, full_monthly_schedule, full_annual_schedule = build_schedules # defaults to 120 years

    male_age   = @user.simulation_input.male_age || 0  # If nil, can't compare with other value
    female_age = @user.simulation_input.female_age || 0 # If nil, can't compare with other value
    number_of_years   = 120 - [male_age, female_age].min
    number_of_weeks   = number_of_years * 52
    number_of_months  = number_of_years * 12

    return {
      weekly:   full_weekly_schedule[0...number_of_weeks],
      monthly:  full_monthly_schedule[0...number_of_months],
      annual:   full_annual_schedule[0...number_of_years]
    }
  end

  def asset_return_data(return_source=:implied_return) # other option for return_source :mean_return
    # NB: If you change the name of this method, update above in warm_cache

    cache_key = "asset_return_data/#{return_source}/#{Security.last_updated_time}"
    Rails.cache.fetch cache_key, compress: true, expires_in: 12.hours do

      # Ordering tickers alphabetically.
      asset_data = Security.statistics_for_all(return_source)

      # Compile descriptive data on securities
      tickers               = asset_data.inject([]) {|array, security| array << security[:ticker]; array}
      return_data           = asset_data.inject({}) {|h, security| h[security[:ticker]] = security[:returns]; h }
      weekly_mean_returns   = asset_data.inject([]) {|array, security| array << security[:mean_return]; array}
      weekly_std_devs       = asset_data.inject([]) {|array, security| array << security[:std_dev]; array}

      # Using monthly data for inflation & real estate - need to be consistent with securities
      monthly_mean_returns  = weekly_mean_returns.map { |weekly_ret|  (1 + weekly_ret.to_f) ** (52/12) - 1 }
      monthly_std_devs      = weekly_std_devs.map {|weekly_sd| weekly_sd.to_f * Math.sqrt(52/12)  }

      ##

      # Compute the correlations/cholesky decomposition.
      correlation_matrix  = Finance::MatrixMethods.correlation(return_data)
      cholesky_decomp     = Finance::MatrixMethods.cholesky_decomposition(correlation_matrix)

      {
        tickers:      tickers,
        mean_returns: monthly_mean_returns,
        std_devs:     monthly_std_devs,
        c_d:          cholesky_decomp
      }

    end # cache fetch
  end

  def build_schedules(number_of_years=120)
    # NB: If you change the name of this method, update above in warm_cache

    number_of_years   = 120
    number_of_weeks   = number_of_years * 52
    number_of_months  = number_of_years * 12

    this_day_of_week        = Date.today.cwday # 1 - 7
    zero_index_day_of_week  = this_day_of_week - 1
    this_day_of_month       = Date.today.day
    this_week               = Date.today.cweek # 1 - 52
    this_month_of_year      = Date.today.month
    this_year               = Date.today.cwyear # Year as integer

    end_date = Date.commercial( this_year + number_of_years, this_week, this_day_of_week )

    # Expire all in just over a day - even annual, as we're still rebuilding the
    # annual schedule every week.
    # All time integers multiplied by 1000 for javascript (s -> ms)
    weekly_schedule = Rails.cache.fetch("schedule/weekly/#{this_day_of_week}", expires_in: 2.days) do
      weeks = Recurrence.new(every: :week, on: (zero_index_day_of_week), until: end_date)
      weeks.events.inject([]) { |ary, date| ary << date.end_of_day.to_i * 1000 }
    end

    monthly_schedule = Rails.cache.fetch("schedule/monthly/#{this_day_of_week}", expires_in: 2.days) do
      months = Recurrence.new(every: :month, on: this_day_of_month, until: end_date)
      months.events.inject([]) { |ary, date| ary << date.end_of_day.to_i * 1000 }
    end

    annual_schedule = Rails.cache.fetch("schedule/annual/#{this_day_of_week}", expires_in: 2.days) do
      years = Recurrence.new(every: :year, on: [this_month_of_year, this_day_of_month], until: end_date) # [month, day]
      years.events.inject([]) { |ary, date| ary << date.end_of_day.to_i * 1000 }
    end

    return weekly_schedule, monthly_schedule, annual_schedule
  end

end
