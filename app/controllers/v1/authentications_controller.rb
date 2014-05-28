module V1

  class AuthenticationsController < ApplicationController
    before_action :authenticate_user!

    def index
      if params[:ids] && params[:ids].present?
        @authentications = current_user.authentications.where(id: params[:ids])
        render json: @authentications if stale?(etag: @authentications)
      else # Standard index action (no IDS array parameter)
        last_modified = current_user.authentications.maximum(:updated_at)
        render json: current_user.authentications.all if stale?(etag: last_modified, last_modified: last_modified)
      end
    end

    def show
      # expires_in 3.minutes, public: true
      authentication = current_user.authentications.find(params[:id])
      render json: authentication if stale?(authentication)
    end

  end

end
