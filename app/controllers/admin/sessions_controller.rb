module Admin
  class SessionsController < ApplicationController
    before_action :authenticate_user!, only: [:destroy]

    def destroy
      # LOGOUT - requires authenticated user
      current_user.sign_out!
      render json: {success: true, message: 'Signed out successfully.'}
    end

    def create
      return missing_parameters unless (params[:email].present? && params[:password].present?)
      user = RegularUser.find_by(email: params[:email])

      if user && user.authenticate(params[:password]) && user.admin?
        logger.warn "[SECURITY] User logged into admin controller: #{params[:email]}"
        user.sign_in!
        render json: user.session_data, status: 201
      else
        return invalid_parameters("Email/password combination is invalid.")
      end
    end

  end
end
