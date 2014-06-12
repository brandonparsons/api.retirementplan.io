module V1

  class MiscController < ApplicationController

    def simulation_count
      render json: {simulations: $redis.get($SIMULATION_COUNT_KEY) }
    end

  end

end
