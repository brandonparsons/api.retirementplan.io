class ApplicationController < ActionController::API

  include ActionController::MimeResponds
  include ActionController::ImplicitRender
  include ActionController::StrongParameters

  before_action :cors_set_access_control_headers


  ###################
  # ERROR RESPONSES #
  ###################

  # Generic fallback - this has to be FIRST
  rescue_from(Exception) do |exception|
    logger.error "[500 ERROR]: #{exception.message}"
    exception.backtrace.each { |line| logger.error line }
    Rollbar.report_exception(exception, rollbar_request_data, rollbar_person_data) if defined?(Rollbar)
    render json: {success: false, message: "Sorry - something went wrong."}, status: 500
  end

  # Postgres will error if calling find without a valid UUID string. Could
  # try to validate UUID's using regex, but that didn't work perfectly on
  # naieve implementation. Just let the database check the format, and 404 if
  # it was invalid.
  rescue_from ActiveRecord::StatementInvalid, with: :record_not_found

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  rescue_from ActionController::ParameterMissing, with: :missing_parameters

  rescue_from ActionController::UnpermittedParameters do |exception|
    logger.warn "[ERROR]: Unpermitted parameters passed to the controller (#{current_user && current_user.email})"
    invalid_parameters
  end

  rescue_from CustomExceptions::InvalidOauthCredentials, with: :invalid_parameters

  rescue_from CustomExceptions::MissingParameters, with: :missing_parameters

  rescue_from CustomExceptions::InvalidParameters, with: :invalid_parameters

  rescue_from CustomExceptions::UserExistsFromOauth do |exception|
    provider = exception.message
    oauth_login_error "That e-mail is already attached to a different provider (try #{provider})."
  end

  rescue_from CustomExceptions::UserExistsWithPassword do |exception|
    oauth_login_error "An account already exists for that email using password registration. Please sign in with your email/password, and then you can add that authentication provider from your profile page."
  end


  protected

  def authenticate_user!
    user_signed_in? ? true : access_denied
  end

  def current_user
    @current_user ||= get_user
  end

  def user_signed_in?
    current_user.present?
  end

  def get_user
    email       = request.headers['X-Auth-Email'] || request.headers['HTTP-X-Auth-Email'] || params[:auth_email]
    auth_token  = request.headers['X-Auth-Token'] || request.headers['HTTP-X-Auth-Token'] || params[:auth_token]
    logger.debug( (email.present? && auth_token.present?) ? "[AUTH_INFO]: #{email} || #{auth_token}" : "[AUTH INFO]: NONE" ) if Rails.env.development?
    User.authenticate_from_email_and_token(email, auth_token)
  end

  def access_denied(message = "Error with your login credentials")
    render json: {success: false, message: message}, status: 401
  end

  def record_not_found
    render json: {success: false, message: "404 - Record Not Found"}, status: 404
  end

  def missing_parameters
    render json: {success: false, message: "422 - Missing parameters"}, status: 422
  end

  def invalid_parameters(message="422 - Invalid parameters")
    render json: {success: false, message: message}, status: 422
  end

  def oauth_login_error(message)
    render json: { success: false, message: message, sticky: 10000 }, status: 422
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

end
