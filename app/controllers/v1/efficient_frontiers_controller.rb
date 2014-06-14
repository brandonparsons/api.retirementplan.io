module V1

  class EfficientFrontiersController < SecuredController

    def show
      return missing_parameters unless params[:tickers].present?
      return invalid_parameters unless params[:tickers].is_a?(Array)
      efficient_frontier = EfficientFrontierCreator.new(params[:tickers]).call
      render json: { efficient_frontier: efficient_frontier } if stale?(etag: efficient_frontier)
    end

  end

end
