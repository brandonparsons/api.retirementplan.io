module V1

  class AuthenticationsController < ApplicationController
    before_action :authenticate_user!

    def index
      if params[:ids] && params[:ids].present?
        @authentications = current_user.authentications.where(id: params[:ids])
        render json: @authentications if stale?(etag: @authentications)
      else # Standard index action (no IDS array parameter)
        last_modified = current_user.authentications.maximum(:updated_at)
        render json: current_user.authentications.all if stale?(etag: last_modified, last_modified: last_modified)
      end
    end

    def create
      # This is similar to the usere#check_oauth route, except that we don't
      # send back email, auth token etc. as we are already logged in. Just
      # create and associate the OAuth authentication.

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
      o = OAuthUser.new({'provider' => provider, 'uid' => uid}, current_user)
      begin
        o.login_or_create # This will create an authentication on the logged-in user
        authentication = o.authentication
      rescue CustomExceptions::ErrorSavingAuthentication => error_messages
        render json: JSON.parse(error_messages.to_s), status: 422 and return
      end

      render json: authentication, status: :created
    end

    def show
      # expires_in 3.minutes, public: true
      authentication = current_user.authentications.find(params[:id])
      render json: authentication if stale?(authentication)
    end

    def destroy
      authentications = current_user.authentications
      if authentications.count > 1 || current_user.has_password?
        authentications.find(params[:id]).destroy
        render json: nil, status: :ok
      else
        render json: {success: false, message: "Can't delete provider - last one, and no user password."}, status: 422
      end
    end

  end

end
