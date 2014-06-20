module V1

  class PortfoliosController < SecuredController
    before_action :ensure_user_completed_questionnaire!

    def create
      return missing_parameters unless params[:allocation]
      portfolio = current_user.build_portfolio(weights: params[:allocation])
      if portfolio.save
        render json: {success: true, message: "Saved your portfolio selection."}
      else
        render json: portfolio.errors, status: :unprocessable_entity
      end
    end

    def show
      portfolio = current_user.portfolio
      if portfolio.present?
        allocation = portfolio.weights
        render json: { portfolio: {id: encode_allocation(allocation), allocation: allocation} } if stale?(portfolio)
      else
        render json: {}
      end
    end


    private

    def encode_allocation(allocation)
      Base64.urlsafe_encode64(allocation.to_json)
    end

  end

end
