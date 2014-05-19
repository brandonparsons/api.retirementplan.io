module Api
  module V1

    class QuestionnairesController < ApplicationController
      before_action :authenticate_user!

      def index
        render json: [current_user.questionnaire]
      end

      def create
        return already_has_questionnaire if current_user.has_questionnaire?

        @questionnaire = current_user.build_questionnaire(questionnaire_params)

        if @questionnaire.save
          render json: @questionnaire, status: :created
        else
          render json: @questionnaire.errors, status: :unprocessable_entity
        end
      end

      def update
        @questionnaire = current_user.questionnaire

        if @questionnaire.update(questionnaire_params)
          render json: @questionnaire, status: :ok
        else
          render json: @questionnaire.errors, status: :unprocessable_entity
        end
      end


      private

      def already_has_questionnaire
        render json: { success: false, message: "422 - You have already created a questionnaire."}, status: 422
      end

      def questionnaire_params
        params[:questionnaire].try(:delete, :user_id)
        params.require(:questionnaire).permit(:age, :sex, :no_people, :real_estate_val, :saving_reason, :investment_timeline, :investment_timeline_length, :economy_performance, :financial_risk, :credit_card, :pension, :inheritance, :bequeath, :degree, :loan, :forseeable_expenses, :married, :emergency_fund, :job_title)
      end

    end # QuestionnairesController

  end
end
