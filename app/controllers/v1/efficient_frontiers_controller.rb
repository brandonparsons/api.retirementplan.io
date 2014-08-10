module V1

  class EfficientFrontiersController < SecuredController
    before_action :ensure_user_completed_questionnaire!

    def show
      return missing_parameters unless params[:asset_ids].present?
      return invalid_parameters unless params[:asset_ids].is_a?(Array)
      efficient_frontier = EfficientFrontierCreator.new(params[:asset_ids]).call
      render json: { efficient_frontier: efficient_frontier } if stale?(etag: efficient_frontier)
    end

  end

end
