class OAuthValidator

  VALID_PROVIDERS = ['facebook', 'google']

  def initialize(submitted_params)
    validate_and_store(submitted_params)
  end

  def call
    # Returns the user's data, or throws if invalid
    send("check_oauth_for_#{@provider}")
  end


  private

  def validate_and_store(params)
    email         = params[:email].to_s
    access_token  = params[:access_token].to_s
    provider      = params[:provider].to_s
    uid           = params[:uid].to_s
    raise CustomExceptions::MissingParameters unless (
      email.present?        &&
      access_token.present? &&
      provider.present?     &&
      uid.present?
    )
    raise CustomExceptions::InvalidParameters unless VALID_PROVIDERS.include?(provider)

    @email        = email
    @access_token = access_token
    @provider     = provider
    @uid          = uid
  end

  def check_oauth_for_facebook
    # Validate the token to ensure it is valid from Facebook, and created by
    # our app.

    token_validation_url  = "https://graph.facebook.com/debug_token"
    conn                  = get_faraday_connection(token_validation_url)

    facebook_response = JSON.parse(conn.get do |req|
      req.params['input_token']   = @access_token
      req.params['access_token']  = [ENV['FACEBOOK_KEY'], ENV['FACEBOOK_SECRET']].join('|')
    end.body)

    raise CustomExceptions::InvalidOauthCredentials, "Returned not valid" unless facebook_response['data']['is_valid'].present? && facebook_response['data']['is_valid']
    raise CustomExceptions::InvalidOauthCredentials, "Wrong App ID"       unless facebook_response['data']['app_id']  == ENV['FACEBOOK_KEY']
    raise CustomExceptions::InvalidOauthCredentials, "Wrong user ID"      unless facebook_response['data']['user_id'] == @uid

    return @uid, @provider
  end

  def check_oauth_for_google
    raise "NEEDS IMPLEMENTING!"
  end

  def get_faraday_connection(url)
    if Rails.env.production?
      # This solution apparently works for heroku. Otherwise just point to /usr/lib/ssl/certs
      ssl = { ca_file: '/usr/lib/ssl/certs/ca-certificates.crt' }
    else
      ssl = false
    end

    return ::Faraday::Connection.new(url, ssl: ssl)
  end

end
