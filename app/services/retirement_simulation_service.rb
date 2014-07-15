class RetirementSimulationService

  def initialize(number_of_trials, portfolio, simulation_inputs, expenses)
    @number_of_trials   = number_of_trials
    @portfolio          = portfolio
    @simulation_inputs  = simulation_inputs
    @expenses           = expenses
  end

  def call
    return format_output(post_to_simulation_service formatted_inputs)
  end


  private

  def format_output(simulation_output)
    simulation_output.map do |timestep|
      timestep.reduce({}) do |memo, (k,v)|
        if k == "date"
          memo[k] = v.to_i
          # memo[k] = Time.at(v.to_i).utc.strftime("%Y-%m-%d")
        else
          memo[k] = v.to_f
        end
        memo
      end
    end
  end

  def post_to_simulation_service(inputs)
    conn = Faraday.new(url: ENV['SIMULATION_APP'])
    return JSON.parse(conn.post do |req|
      req.url '/simulation'
      req.headers['Content-Type']   = 'application/json'
      req.headers['Authorization']  = ENV['AUTH_TOKEN']
      req.body                      = inputs.to_json
    end.body)["timesteps"]
  end

  def formatted_inputs
    asset_weights = @portfolio.weights
    asset_ids     = @portfolio.weights.keys

    return {
      number_of_trials: @number_of_trials,
      selected_portfolio_weights: FloatMapper.call(asset_weights),
      asset_performance_data: asset_performance_for(asset_ids),
      cholesky_decomposition: finance_service_get('/cholesky', body: {asset_ids: asset_ids})["cholesky_decomposition"].map(&:to_f),
      inflation: FloatMapper.call(finance_service_get('/inflation')),
      real_estate: FloatMapper.call(finance_service_get('/real_estate')),
      expenses: formatted_expenses(@expenses),
      simulation_parameters: formatted_simulation_inputs(@simulation_inputs),
    }
  end

  def asset_performance_for(asset_ids)
    return finance_service_get('/performance', body: {asset_ids: asset_ids}).reduce({}) do |memo, (asset_id, stats)|
      memo[asset_id] = FloatMapper.call(stats)
      memo
    end
  end

  def finance_service_get(url, param: nil, param_value: nil, body: nil)
    conn = Faraday.new(url: ENV['FINANCE_APP'])
    JSON.parse(conn.get do |req|
      req.url url
      req.headers['Content-Type']   = 'application/json'
      req.headers['Authorization']  = ENV['AUTH_TOKEN']
      req.params[param]             = param_value if param && param_value
      req.body                      = body.to_json if body
    end.body)
  end

  def formatted_expenses(expenses)
    expenses.to_a.map do |expense|
      obj               = {}
      obj[:amount]      = expense.amount.to_f
      obj[:frequency]   = expense.frequency
      obj[:onetime_on]  = expense.onetime_on.try(:utc).try(:to_i)
      obj[:ends]        = expense.ends.try(:utc).try(:to_i)
      obj
    end
  end

  def formatted_simulation_inputs(simulation_inputs)
    return {
      male: simulation_inputs.user_is_male,
      married: simulation_inputs.married,
      retired: simulation_inputs.user_retired,
      male_age: simulation_inputs.male_age.to_i,
      retirement_age_male: simulation_inputs.retirement_age_male.to_i,
      female_age: simulation_inputs.female_age.to_i,
      retirement_age_female: simulation_inputs.retirement_age_female.to_i,
      expenses_multiplier: simulation_inputs.expenses_multiplier.to_f,
      fraction_single_income: simulation_inputs.fraction_for_single_income.to_f,
      starting_assets: simulation_inputs.assets.to_f,
      income: simulation_inputs.income.to_f,
      current_tax: simulation_inputs.current_tax_rate.to_f,
      salary_increase: simulation_inputs.salary_increase.to_f,
      income_inflation_index: simulation_inputs.income_inflation_index.to_f,
      expenses_inflation_index: simulation_inputs.expenses_inflation_index.to_f,
      retirement_income: simulation_inputs.retirement_income.to_f,
      retirement_expenses: simulation_inputs.retirement_expenses.to_f,
      retirement_tax: simulation_inputs.retirement_tax_rate.to_f,
      life_insurance: simulation_inputs.life_insurance.to_f,
      include_home: simulation_inputs.include_home,
      home_value: simulation_inputs.home_value.to_f,
      sell_house_in: simulation_inputs.sell_house_in.to_i,
      new_home_relative_value: simulation_inputs.new_home_relative_value.to_i
    }
  end

end
