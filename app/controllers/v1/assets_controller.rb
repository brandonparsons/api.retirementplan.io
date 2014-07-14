module V1

  class AssetsController < SecuredController

    def index
      json = AssetsService.get_as_json
      render json: json if stale?(etag: json)
    end

    def show
      assets = AssetsService.get_as_objects

      asset       = assets.find{|asset| asset.id == params[:id]}
      asset_json  = Oj.dump({"asset" => asset.as_json})

      render json: asset_json if stale?(asset_json)
    end

  end

end
