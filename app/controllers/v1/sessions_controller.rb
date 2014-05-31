module V1

  class SessionsController < ApplicationController
    before_action :authenticate_user!, except: [:create, :check_oauth]

    def create
      # This route is used to validate a user via POST request with email/password

      return missing_parameters unless (params[:email].present? && params[:password].present?)
      user = RegularUser.find_by(email: params[:email])

      if user && authenticate_user(user, params[:password])
        user.sign_in!
        render json: user.session_data, status: 201
      else
        return invalid_email_login
      end
    end

    def check_oauth
      # After logging in via OAuth (hello.js), this route is used to confirm
      # user identity before giving them an access token (i.e. their OAuth
      # access token is real).

      oauth_user_data         = validate_params(params[:user])
      user, user_was_created  = validate_oauth_and_login(oauth_user_data)

      user.sign_in!(image_url: oauth_user_data[:image])
      user.notify_admin_of_signup! if user_was_created # For brand-new users, send admin notification email
      render json: user.session_data
    end

    def destroy
      current_user.sign_out!
      render json: {success: true, message: 'Signed out successfully.'}
    end


    private

    def authenticate_user(user, password)
      begin
        user.authenticate(params[:password])
      rescue
        return invalid_email_login
      end
      return true
    end

    def validate_params(oauth_user_data)
      return missing_parameters unless oauth_user_data.present?
      return missing_parameters unless oauth_user_data[:name].present?
      return missing_parameters unless oauth_user_data[:image].present?

      return oauth_user_data
    end

    def validate_oauth_and_login(oauth_user_data)
      # This will throw:
      # - CustomExceptions::MissingParameters unless all required params are present
      # - CustomExceptions::InvalidOauthCredentials if invalid access token, etc.
      # These are rescued in application_controller.rb and return error JSON
      uid, provider = ::OAuthValidator.new(oauth_user_data).call

      begin
        user, user_was_created = OAuthUser.new({
          'provider'  => provider,
          'uid'       => uid,
          'email'     => oauth_user_data[:email],
          'name'      => oauth_user_data[:name]
        }, current_user).login_or_create
      rescue CustomExceptions::UserExistsFromOauth => e
        provider = e.message
        return oauth_login_error "That e-mail is already attached to a different provider (try #{provider})."
      rescue CustomExceptions::UserExistsWithPassword
        return oauth_login_error "An account already exists for that email using password registration. Please sign in with your email/password, and then you can add that Authentication provider from your profile page."
      end

      return user, user_was_created
    end

    def oauth_login_error(message)
      render json: { success: false, message: message, sticky: true }, status: :invalid_parameters
    end

    def invalid_email_login
      render json: {success: false, message: "Email/password combination is invalid."}, status: 422
    end

  end # SessionsController

end # module
