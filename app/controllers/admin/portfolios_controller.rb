module Admin
  class PortfoliosController < AdminController
    def index
      render json: Questionnaire.all, each_serializer: AdminPortfolioSerializer
    end
  end
end
