module V1

  class QuestionnairesController < SecuredController

    def index
      if params[:ids] && params[:ids].present?
        # Purposefully getting an array, rather than current_user.questionnaire
        @questionnaires = Questionnaire.where(id: params[:ids], user_id: current_user.id)
        render json: @questionnaires if stale?(etag: @questionnaires)
      else # Standard index action (no IDS array parameter)
        if last_modified = current_user.questionnaire.try(:updated_at)
          # Purposefully getting an array, rather than current_user.questionnaire
          render json: Questionnaire.where(user_id: current_user.id) if stale?(etag: last_modified, last_modified: last_modified)
        else
          render json: {questionnaires: []}
        end
      end
    end

    def show
      render json: current_user.questionnaire
    end

    def create
      questionnaire = current_user.build_questionnaire(questionnaire_params)
      if questionnaire.save
        render json: questionnaire, status: :created
      else
        render json: questionnaire.errors, status: :unprocessable_entity
      end
    end

    def update
      questionnaire = current_user.questionnaire
      if questionnaire.update_attributes(questionnaire_params)
        render json: questionnaire, status: :ok
      else
        render json: questionnaire.errors, status: :unprocessable_entity
      end
    end


    private

    def questionnaire_params
      params.require(:questionnaire).permit(:age, :sex, :no_people,
        :real_estate_val, :saving_reason, :investment_timeline,
        :investment_timeline_length, :economy_performance, :financial_risk,
        :credit_card, :pension, :inheritance, :bequeath, :degree, :loan,
        :forseeable_expenses, :married, :emergency_fund, :job_title,
        :investment_experience
      )
    end

  end

end
