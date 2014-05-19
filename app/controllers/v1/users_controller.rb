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


    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

  end

end
