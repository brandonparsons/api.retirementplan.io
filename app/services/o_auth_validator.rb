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
    access_token  = params[:access_token].to_s
    provider      = params[:provider].to_s
    email         = params[:email].to_s
    raise CustomExceptions::MissingParameters unless (
      access_token.present? && provider.present? && email.present?
    )
    raise CustomExceptions::InvalidParameters unless VALID_PROVIDERS.include?(provider)

    @access_token = access_token
    @provider     = provider
    @email        = email
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
    raise CustomExceptions::InvalidOauthCredentials, "Wrong App ID"       unless facebook_response['data']['app_id'].to_s  == ENV['FACEBOOK_KEY']

    # Validate passed user details
    user_validation_url = "https://graph.facebook.com/me"
    conn = get_faraday_connection(user_validation_url)

    facebook_response = JSON.parse(conn.get do |req|
      req.params['access_token'] = @access_token
    end.body)
    raise CustomExceptions::InvalidOauthCredentials, "Invalid email" unless facebook_response['email'] == @email

    # Return uid/provider
    return facebook_response['id'], @provider
  end

  def check_oauth_for_google
    # Validate the token to ensure it is valid from Google, and created by
    # our app.  Validate user data matches passed information.
    token_validation_url  = "https://www.googleapis.com/oauth2/v1/tokeninfo"
    conn                  = get_faraday_connection(token_validation_url)

    google_response = JSON.parse(conn.get do |req|
      req.params['access_token'] = @access_token
    end.body)

    raise CustomExceptions::InvalidOauthCredentials, "Returned not valid" unless google_response['issued_to'].present?
    raise CustomExceptions::InvalidOauthCredentials, "Wrong App ID"       unless google_response['issued_to']  == ENV['GOOGLE_CLIENT_ID']
    raise CustomExceptions::InvalidOauthCredentials, "Invalid email"      unless google_response['email'] == @email

    return google_response['user_id'], @provider
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
