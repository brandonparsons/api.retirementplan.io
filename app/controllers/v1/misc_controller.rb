module V1

  class MiscController < ApplicationController
    # No auth required

    def simulation_count
      render json: {simulations: $redis.get($SIMULATION_COUNT_KEY) }
    end
  end

end
