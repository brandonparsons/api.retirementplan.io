module V1

  class SessionsController < ApplicationController
    before_action :authenticate_user!, only: [:destroy]

    def create
      return missing_parameters unless (params[:email].present? && params[:password].present?)
      user = RegularUser.find_by(email: params[:email])

      if user && user.authenticate(params[:password])
        user.sign_in!
        data = {
          user_token: user.authentication_token,  # Used to log in ember-simple-auth
          user_email: user.email,                 # Used to log in ember-simple-auth
          user_id:    user.id,                    # Used to set google analytics userId
          user_name:  user.name                   # Used for navbar name
        }
        render json: data, status: 201
      else
        render json: {success: false, message: "Email/password combination is invalid."}, status: :unauthorized
      end
    end

    def destroy
      current_user.sign_out!
      render json: {success: true, message: 'Signed out successfully.'}
    end

  end

end
