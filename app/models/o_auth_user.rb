class OAuthUser

  attr_reader :user

  def initialize creds, user = nil
    @auth         = creds
    @user         = user
    @provider     = @auth.provider
    @policy       = "#{@provider}_policy".classify.constantize.new(@auth)
  end

  def login_or_create
    logged_in? ? create_new_authentication : (login || create_new_authentication)
  end

  def logged_in?
    @user.present?
  end


  private

  def login
    @authentication = Authentication.where(@auth.slice("provider", "uid")).first
    if @authentication.present?
      refresh_tokens
      @user = @authentication.user
      @policy.refresh_callback(@authentication)
    else
      false
    end
  end

  def authentication_already_exists?
    @user.authentications.exists?(provider: @provider, uid: @policy.uid)
  end

  def create_new_authentication
    create_new_user if @user.nil?

    unless authentication_already_exists?
      @authentication = @user.authentications.create!(
        provider:      @provider,
        uid:           @policy.uid,
        oauth_token:   @policy.oauth_token,
        oauth_expires: @policy.oauth_expires,
        oauth_secret:  @policy.oauth_secret,
        username:      @policy.username
      )

      @policy.create_callback(@authentication)
    end
  end

  def create_new_user
    if User.exists? email: @policy.email
      user = User.find_by email: @policy.email
      if user.from_oauth
        provider = user.authentications.first.provider
        raise CustomExceptions::UserExistsFromOauth, Authentication.pretty_provider(provider)
      else
        raise CustomExceptions::UserExistsWithPassword
      end
    end

    password = friendly_token

    @user = User.create!(
      # image:  image,
      name:                   @policy.name,
      email:                  @policy.email,
      password:               password,
      password_confirmation:  password,
      ### Not setting a confirmed at time. We do want to confirm their email on the way in
      from_oauth:             true
    )
    @user.notify_admin_of_signup!
  end

  def friendly_token
    SecureRandom.urlsafe_base64(15).tr('lIO0', 'sxyz')
  end

  # def image
  #   image = open(URI.parse(@policy.image_url), :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE)
  #   def image.original_filename; base_uri.path.split('/').last; end
  #   image
  # end

  def refresh_tokens
    @authentication.update_attributes(
      oauth_token:   @policy.oauth_token,
      oauth_expires: @policy.oauth_expires,
      oauth_secret:  @policy.oauth_secret
    )
  end

end
