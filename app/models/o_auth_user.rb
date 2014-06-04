class OAuthUser

  attr_reader :authentication

  def initialize(auth_data, user = nil)
    @user             = user

    @provider         = auth_data['provider']
    @uid              = auth_data['uid']
    @email            = auth_data['email']
    @name             = auth_data['name']

    @user_was_created           = false
  end

  def login_or_create
    logged_in? ? create_new_authentication : (login || create_new_authentication)
    return @user, @user_was_created
  end

  def logged_in?
    @user.present?
  end


  private

  def login
    @authentication = Authentication.find_by(
      provider: @provider,
      uid:      @uid
    )

    if @authentication.present?
      # This is where you would refresh_tokens (and upgrade server-side token to
      # a long-lived token) if you want to be doing that
      @user = @authentication.user
    else
      false
    end
  end

  def authentication_already_exists?
    @user.authentications.exists?(provider: @provider, uid: @uid)
  end

  def create_new_authentication
    create_new_user if @user.nil?

    if authentication_already_exists?
      @authentication = @user.authentications.find_by(provider: @provider, uid: @uid)
    else
      @authentication = @user.authentications.build(
        provider:   @provider,
        uid:        @uid,
        username:   @name
      )
      if @authentication.valid?
        @authentication.save
      else
        raise CustomExceptions::ErrorSavingAuthentication, JSON.dump(@authentication.errors.messages)
      end
    end

    return true
  end

  def create_new_user
    if User.exists? email: @email
      user = User.find_by email: @email
      if user.from_oauth
        provider = user.authentications.first.provider
        raise CustomExceptions::UserExistsFromOauth, Authentication.pretty_provider(provider)
      else
        raise CustomExceptions::UserExistsWithPassword
      end
    end

    @user = User.create!(
      email:        @email,
      name:         @name,
      from_oauth:   true
      # Not setting confirmed_at, still need to confirm OAuth user's email
    )

    @user_was_created = true
  end

end
