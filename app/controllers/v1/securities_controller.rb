module V1

  class SecuritiesController < ApplicationController
    before_action :authenticate_user!

    def index
      if params[:ids].present?
        @securities = Security.where(id: params[:ids]) if params[:ids]
      else
        @securities = Security.all
      end
      render json: @securities
    end

    def show
      render json: Security.find(params[:id])
    end

  end

end
