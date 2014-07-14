module V1

  class SimulationsController < SecuredController
    before_action :ensure_user_completed_questionnaire!
    before_action :ensure_user_selected_portfolio!
    before_action :ensure_user_selected_expenses!
    before_action :ensure_user_has_simulation_input!

    def show
      return missing_parameters unless params[:number_of_simulation_trials]
      render json: RetirementSimulator.new(current_user.portfolio, current_user.simulation_input, params[:number_of_simulation_trials]).call
    end

    def create
      current_user.has_completed_simulation!
      render json: nil, status: :ok
    end

  end

end
