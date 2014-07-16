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

end
