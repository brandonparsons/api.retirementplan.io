module V1

  class UsersController < ApplicationController
    before_filter :authenticate_user!, except: [:create, :new_password_reset, :request_password_reset]


    #####################
    # No login required #
    #####################

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

    def new_password_reset
      return missing_parameters unless params[:email].present?
      UserMailer.delay.reset_password_instructions(params[:email])
      render json: {success: true, message: "Email being sent to #{params[:email]}"}
    end

    def request_password_reset
      return missing_parameters unless params[:password_reset_token].present?
      return missing_parameters unless params[:password].present?
      return missing_parameters unless params[:password_confirmation].present?

      token = CGI.unescape(params[:password_reset_token])

      # For some reason, this can't be pulled into the model.... it fails every time
      begin
        # This raises an exception if the message is modified
        user_id, timestamp = RegularUser.verifier_for('password-reset').verify(token)
      rescue
        return render json: {success: false, message: "Invalid password reset token."}, status: 422
      end

      if (RegularUser.normalized_timestamp - timestamp) > 1.day
        return render json: {success: false, message: "That token has expired. Request another token and start over."}, status: 422
      end

      user = RegularUser.find_from_all_users_with_id(user_id)
      return invalid_parameters unless user.present?

      user.password               = params[:password]
      user.password_confirmation  = params[:password_confirmation]
      if user.save
        render json: {success: true, message: 'Password changed.'}
      else
        render json: user.errors, status: 422
      end
    end


    ##################
    # Login required #
    ##################

    def show
      render json: current_user
    end

    def update
      ## This update method will only work if the user has a password - i.e. if
      ## the user was created from OAuth, they will need to set a password before
      ## they can change their name/email.
      return invalid_parameters unless current_user.has_password?

      # Validate the current password
      return missing_parameters unless params[:user][:current_password].present?
      user = RegularUser.find_from_all_users_with_id current_user.id # current_user is a `User` not a `RegularUser`
      return invalid_parameters unless user.present?
      return invalid_parameters("Current password is incorrect.") unless user.authenticate(params[:user][:current_password])

      # After validation, don't want this in the params
      params[:user].delete(:current_password)

      # Update the user. This will work with pass/pass_conf
      if user.update_attributes(user_update_params)
        render json: UserSerializer.new(user).as_json, status: :ok
      else
        render json: user.errors, status: :unprocessable_entity
      end
    end

    def create_password
      email = current_user.email
      UserMailer.delay.reset_password_instructions(email, set_password_request: true)
      render json: {success: true, message: "Email being sent to #{email} with instructions on how to set a password."}
    end


    private

    def user_create_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def user_update_params
      params.require(:user).permit(:name, :email, :current_password, :password, :password_confirmation)
    end

  end

end
