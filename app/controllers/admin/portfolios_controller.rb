module Admin
  class PortfoliosController < AdminController
    def index
      render json: Portfolio.all, each_serializer: AdminPortfolioSerializer
    end
  end
end
