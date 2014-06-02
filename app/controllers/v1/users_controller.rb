module V1

  class UsersController < ApplicationController
    before_filter :authenticate_user!, except: [:create]

    def create
      @user = RegularUser.new(user_create_params)
      if @user.save
        @user.sign_in!
        @user.notify_admin_of_signup!
        render json: UserSerializer.new(@user).as_json, status: 201
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end

    def show
      log_if_attempted_improper_access
      render json: current_user
    end

    def update
      log_if_attempted_improper_access
      if current_user.update_attributes(user_update_params)
        render json: current_user, status: :ok
      else
        render json: current_user.errors, status: :unprocessable_entity
      end
    end


    private

    def log_if_attempted_improper_access
      if params[:id] != current_user.id
        logger.warn "[SECURITY]: Someone trying to look at someone else's profile... USERID: #{current_user.id}"
      end
    end

    def user_create_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def user_update_params
      params[:user].try(:delete, :image) # Ember will send the image back on save
      params.require(:user).permit(:name, :email)
    end

  end

end
