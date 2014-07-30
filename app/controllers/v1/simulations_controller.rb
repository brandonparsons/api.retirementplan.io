module V1

  class SimulationsController < SecuredController
    before_action :ensure_user_completed_questionnaire!
    before_action :ensure_user_selected_portfolio!
    before_action :ensure_user_selected_expenses!
    before_action :ensure_user_has_simulation_input!

    def show
      return missing_parameters unless params[:number_of_simulation_trials]

      number_of_trials = params[:number_of_simulation_trials].to_i
      return bad_request unless number_of_trials <= 1000

      portfolio = current_user.portfolio
      inputs    = current_user.simulation_input
      expenses  = current_user.expenses.where(is_added: true)

      current_user.ran_simulations!(number_of_trials)
      $redis.incrby $SIMULATION_COUNT_KEY, number_of_trials

      render json: RetirementSimulationService.new(number_of_trials, portfolio, inputs, expenses).call
    end

    def create
      current_user.has_completed_simulation!
      render json: nil, status: :ok
    end

  end

end
