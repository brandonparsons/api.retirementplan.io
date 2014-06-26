module V1

  class SimulationInputsController < SecuredController
    before_action :ensure_user_completed_questionnaire!
    before_action :ensure_user_selected_portfolio!
    before_action :ensure_user_selected_expenses!

    def index
      if params[:ids] && params[:ids].present?
        # Purposefully getting an array, rather than current_user.sim_inputs
        inputs = SimulationInput.where(id: params[:ids], user_id: current_user.id)
        render json: inputs if stale?(etag: inputs)
      else # Standard index action (no IDS array parameter)
        if last_modified = current_user.simulation_input.try(:updated_at)
          # Purposefully getting an array, rather than current_user.questionnaire
          render json: SimulationInput.where(user_id: current_user.id) if stale?(etag: last_modified, last_modified: last_modified)
        else
          render json: {simulation_inputs: []}
        end
      end
    end

    def show
      simulation_input = current_user.simulation_input
      render json: simulation_input if stale?(simulation_input)
    end

    def create
      inputs = current_user.build_simulation_input(input_params)
      if inputs.save
        render json: inputs, status: :created
      else
        render json: inputs.errors, status: :unprocessable_entity
      end
    end

    def update
      inputs = current_user.simulation_input
      if inputs.update_attributes(input_params)
        render json: inputs, status: :ok
      else
        render json: inputs.errors, status: :unprocessable_entity
      end
    end


    private

    def input_params
      params.require(:simulation_input).permit(:user_is_male,
        :married, :male_age, :female_age, :user_retired, :retirement_age_male,
        :retirement_age_female, :assets, :expenses_inflation_index,
        :life_insurance, :income, :current_tax_rate, :salary_increase,
        :retirement_income, :retirement_expenses, :retirement_tax_rate,
        :income_inflation_index, :include_home, :home_value, :sell_house_in,
        :new_home_relative_value, :expenses_multiplier,
        :fraction_for_single_income)
    end

  end

end
