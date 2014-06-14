# routes.rb (top)

# CORS requests will send a pre-flight OPTIONS request that we need to handle
match '*path',  to: 'application#CORS', via: [:options]


# application_controller.rb

before_action :cors_set_access_control_headers


def CORS
  render text: '', content_type: 'text/plain'
end


def cors_set_access_control_headers
  headers['Access-Control-Allow-Origin']    = Rails.env.production? ? ENV['FRONTEND'] : '*'
  headers['Access-Control-Request-Method']  = '*'
  headers['Access-Control-Max-Age']         = "1728000"

  headers['Access-Control-Allow-Methods']   = %w{
    POST
    PUT
    PATCH
    DELETE
    GET
    OPTIONS
  }.join(', ')

  headers['Access-Control-Allow-Headers']   = %w{
    Origin
    X-Requested-With
    Content-Type
    Accept
    X-Auth-Email
    X-Auth-Token
  }.join(', ')
end
