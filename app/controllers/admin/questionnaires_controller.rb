module Admin
  class QuestionnairesController < AdminController
    def index
      render json: Questionnaire.all, each_serializer: AdminQuestionnaireSerializer
    end
  end
end
