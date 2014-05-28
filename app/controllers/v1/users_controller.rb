module V1

  class UsersController < ApplicationController
    before_filter :authenticate_user!, except: [:create]

    def create
      @user = RegularUser.new(user_params)
      if @user.save
        @user.sign_in!
        @user.notify_admin_of_signup!
        data = {
          user_token: user.authentication_token,
          user_email: user.email
        }
        render json: data, status: 201
      else
        render json: @user, status: 422
      end
    end

    def add_oauth
      # This is similar to the check_oauth route, except that we don't send back
      # email, auth token etc. as we are already logged in. Just create and
      # associate the OAuth authentication.

      oauth_user_data = params[:user]
      return missing_parameters unless oauth_user_data.present?

      # This will throw:
      # - CustomExceptions::MissingParameters unless all required params are present
      # - CustomExceptions::InvalidOauthCredentials if invalid access token, etc.
      # These are rescued in application_controller.rb and return error JSON
      uid, provider = ::OAuthValidator.new(oauth_user_data).call

      # No need to rescue CustomExceptions::UserExistsFromOauth or
      # CustomExceptions::UserExistsWithPassword as this will always be called
      # with a current_user present.
      o = OAuthUser.new({
        'provider'  => provider,
        'uid'       => uid,
        'email'     => oauth_user_data[:email],
        'name'      => oauth_user_data[:name],
        'image'     => oauth_user_data[:image]
      }, current_user)

      o.login_or_create
      authentication = o.authentication

      render json: authentication, status: :created
    end

    def show
      if params[:id] != current_user.id
        logger.warn "[SECURITY]: Someone trying to look at someone else's profile... USERID: #{current_user.id}"
      end
      render json: current_user
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

  end

end
