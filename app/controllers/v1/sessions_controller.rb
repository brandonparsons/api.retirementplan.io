module V1

  class SessionsController < ApplicationController
    before_action :authenticate_user!, except: [:create, :check_oauth]

    ## REQUIRES LOGIN! ##
    def destroy
      # Logout
      current_user.sign_out!
      render json: {success: true, message: 'Signed out successfully.'}
    end
    ##                 ##

    def create
      # This route is used to validate a user via POST request with email/password

      return missing_parameters unless (params[:email].present? && params[:password].present?)
      user = RegularUser.find_by(email: params[:email])

      if user && user.authenticate(params[:password])
        user.sign_in!
        render json: user.session_data, status: 201
      else
        return invalid_parameters("Email/password combination is invalid.")
      end
    end

    def check_oauth
      # After logging in via OAuth (hello.js), this route is used to confirm
      # user identity before giving them an access token (i.e. their OAuth
      # access token is real).
      oauth_user_data = params[:user]
      return missing_parameters unless oauth_user_data.present?
      return missing_parameters unless oauth_user_data[:name].present?
      return missing_parameters unless oauth_user_data[:image].present?

      user, user_was_created  = validate_oauth_and_login(oauth_user_data)

      user.sign_in!(image_url: oauth_user_data[:image])
      ::CreateUserService.new(user).call if user_was_created
      render json: user.session_data
    end


    private

    def validate_oauth_and_login(oauth_user_data)
      # This will throw:
      # - CustomExceptions::MissingParameters unless all required params are present
      # - CustomExceptions::InvalidOauthCredentials if invalid access token, etc.
      # These are rescued in application_controller.rb and return error JSON
      uid, provider = ::OAuthValidator.new(oauth_user_data).call

      # This will throw:
      # - CustomExceptions::UserExistsFromOauth if that email already has a different OAuth service attached
      # - CustomExceptions::UserExistsWithPassword if user has been created with email/password
      # These are rescued in application_controller.rb and return error JSON
      user, user_was_created = OAuthUser.new({
        'provider'  => provider,
        'uid'       => uid,
        'email'     => oauth_user_data[:email],
        'name'      => oauth_user_data[:name]
      }, current_user).login_or_create

      return user, user_was_created
    end

  end

end # module
