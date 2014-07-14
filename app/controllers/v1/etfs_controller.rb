module V1

  class EtfsController < SecuredController

    def index
      json = EtfsService.get_as_json
      render json: json if stale?(etag: json)
    end

    def show
      etfs = EtfsService.get_as_objects

      etf       = etfs.find{|etf| etf.id == params[:id]}
      etf_json  = Oj.dump({"etf" => etf.as_json})

      render json: etf_json if stale?(etf_json)
    end

  end

end
