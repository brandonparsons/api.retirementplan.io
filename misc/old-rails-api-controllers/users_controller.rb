module Api
  module V1

    class UsersController < ApplicationController
      before_action :authenticate_user!, except: [:index, :create]

      def index
        return render json: {}, status: 403
        if user_signed_in?
          render json: [current_user]
        else
          render json: []
        end
      end

      def create
        user = User.new(user_create_params)
        if user.save
          user_json = UserSerializer.new(user).as_json
          auth_info = { access_token: user.authentication_token }
          return render json: auth_info.merge(user_json).to_json, status: 201
        else
          render json: user.errors, status: 422
        end
      end

      def update_profile
        @user = current_user
        user_params = user_update_profile_params

        if @user.authenticate(user_params[:current_password])

          user_params.delete :current_password

          if @user.update_attributes(user_params)
            render json: @user, status: :ok
          else
            render json: {errors: @user.errors}, status: :unprocessable_entity
          end

        else
          access_denied("Your current password was entered incorrectly.")
        end

      end

      def change_password
        @user = current_user
        password_params = user_password_params

        if @user.authenticate(password_params["current_password"])
          @user.password = password_params["password"]
          @user.password_confirmation = password_params["password_confirmation"]
          if @user.save
            render json: {message: "Password updated."}, status: :ok
          else
            render json: @user.errors, status: :unprocessable_entity
          end
        else
          access_denied("Your current password was entered incorrectly.")
        end
      end


      private

      def user_create_params
        params.require(:user).permit(:name, :email, :password, :password_confirmation)
      end

      def user_update_profile_params
        params.require(:user).permit(:name, :email, :current_password)
      end

      def user_password_params
        params.require(:user).permit(:password, :password_confirmation, :current_password)
      end


    end

  end
end
