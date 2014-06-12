module V1

  class SecuritiesController < SecuredController

    def index
      if params[:ids] && params[:ids].present? # Ember data will apparently hit index action with ids array
        @securities = Security.where(id: params[:ids])
        render json: @securities if stale?(etag: @securities)
      else # Standard index action (no IDS array parameter)
        last_modified = Security.maximum(:updated_at)
        render json: Security.all if stale?(etag: last_modified, last_modified: last_modified)
      end
    end

    def show
      # expires_in 3.minutes, public: true
      security = Security.find(params[:id])
      render json: security if stale?(security)
    end

  end

end
