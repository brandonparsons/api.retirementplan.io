module V1

  class MiscController < ApplicationController
    before_action :authenticate_user!, except: [:simulation_count]

    def simulation_count
      render json: {simulations: $redis.get($SIMULATION_COUNT_KEY) }
    end
  end

end
