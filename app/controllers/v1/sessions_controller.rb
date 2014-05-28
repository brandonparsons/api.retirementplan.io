module V1

  class SessionsController < ApplicationController
    before_action :authenticate_user!, except: [:create, :check_oauth]

    def create
      # This route is used to validate a user via POST request with email/password

      return missing_parameters unless (params[:email].present? && params[:password].present?)
      user = RegularUser.find_by(email: params[:email])

      if user && user.authenticate(params[:password])
        user.sign_in!

        session_data = {
          user_id:      user.id,                    # Used to set google analytics userId
          user_token:   user.authentication_token,  # Used to log in ember-simple-auth
          user_email:   user.email,                 # Used to log in ember-simple-auth
          user_name:    user.name,                  # Used for navbar name
          user_image:   user.image_url,             # Used for navbar image
          has_password: 'yes'                       # Can't save a boolean value in localStorage || Used to differentiate localStorage response for user/pass
        }

        render json: session_data, status: 201
      else
        render json: {success: false, message: "Email/password combination is invalid."}, status: :unauthorized
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
          'name'      => oauth_user_data[:name],
          'image'     => oauth_user_data[:image]
        }, current_user).login_or_create
      rescue CustomExceptions::UserExistsFromOauth => e
        provider = e.message
        render json: {
          success: false,
          message: "That e-mail is already attached to a different provider (try #{provider})."
        }, status: :unauthorized and return
      rescue CustomExceptions::UserExistsWithPassword
        render json: {
          success: false,
          message: "An account already exists for that email using password registration. Please sign in with your email/password."
        }, status: :unauthorized and return
      end

      user.sign_in!

      # For brand-new users, send admin notification email
      user.notify_admin_of_signup! if user_was_created

      session_data = {
        user_id:      user.id,
        user_token:   user.authentication_token,
        user_email:   user.email,
        user_name:    oauth_user_data[:name], # user.name
        user_image:   oauth_user_data[:image],
        has_password: 'no' # Can't save a boolean value in localStorage
      }

      render json: session_data
    end

    def destroy
      current_user.sign_out!
      render json: {success: true, message: 'Signed out successfully.'}
    end

  end # SessionsController

end # module
