module V1

  class EtfsController < SecuredController

    def index
      if params[:ids] && params[:ids].present?
        # Ember data will apparently hit index action with ids array
        etfs = Etf.where(id: params[:ids])
        render json: etfs if stale?(etag: etfs)

      elsif params[:for_securities]
        # In the track_portfolio route, we only want the ETFs that match specific
        # securities.
        etfs = Security.includes(:etfs).where(ticker: params[:for_securities]).inject([]) do |ary, security|
          ary.push(security.etfs)
          ary
        end.flatten!
        render json: etfs if stale?(etag: etfs)

      else # Standard index action (no IDS array parameter)
        last_modified = Etf.maximum(:updated_at)
        render json: Etf.all if stale?(etag: last_modified, last_modified: last_modified)
      end
    end

    def show
      # expires_in 3.minutes, public: true
      etf = Etf.find(params[:id])
      render json: etf if stale?(etf)
    end

  end

end
