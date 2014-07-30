module V1

  class MiscController < ApplicationController

    def simulation_count
      render json: {simulations: $redis.get($SIMULATION_COUNT_KEY) }
    end

    def js_error
      stack   = params[:stack]
      json    = params[:responseJSON]
      message = params[:message]

      if defined?(Rollbar)
        Rollbar.report_message("[JS Error]: #{message}", "error",
          rollbar_person_data, {
          stack: stack,
          json: json,
          message: message
        })
      else
        logger.warn "JS Error Report:"
        logger.warn stack
        logger.warn json
        logger.warn message
      end

      render json: {success: true, message: 'Error posted.'}
    end

  end

end
