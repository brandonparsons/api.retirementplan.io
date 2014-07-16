class MiscController < ApplicationController

  def home
    render text: "RP.io API Server"
  end

  def error
    raise "Test error"
  end

  def health
    render text: "OK"
  end

  def CORS
    render text: '', content_type: 'text/plain'
  end

  def js_error
    stack   = params[:stack]
    json    = params[:responseJSON]
    message = params[:message]

    if defined?(Rollbar)
      Rollbar.report_message("JS Error Reported!", "warning", {
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
  end

end
