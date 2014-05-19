module Api
  module V1

    class EtfsController < ApplicationController
      before_action :authenticate_user!

      def index
        # TODO: Cache fetch for entire response
        last_modified = Etf.select("updated_at").order("updated_at ASC").last.updated_at
        if stale?(etag: last_modified, last_modified: last_modified)
          render json: Etf.all
        end
      end

    end

  end
end
