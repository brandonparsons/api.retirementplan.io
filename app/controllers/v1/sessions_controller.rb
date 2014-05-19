module V1

  class SessionsController < ApplicationController

    before_action :authenticate_user!, only: [:destroy]

    def create
      submitted_email     = params[:user][:email]
      submitted_password  = params[:user][:password]
      return missing_parameters unless (submitted_email.present? && submitted_password.present?)

      user = RegularUser.find_by(email: submitted_email)

      if user && user.authenticate(submitted_password)
        user.sign_in!
        data = {
          user_token: user.authentication_token,
          user_email: user.email
        }
        render json: data, status: 201
      else
        render json: {error: "Email or password is invalid"}, status: :unauthorized
      end
    end

    def destroy
      current_user.sign_out!
      render json: {status: :success, message: 'Signed out successfully.'}
    end

  end

end
