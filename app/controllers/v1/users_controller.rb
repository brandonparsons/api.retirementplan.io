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

      user = RegularUser.find_by_id_for_password_reset(user_id)
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

    def change_password
      return missing_parameters unless params[:user].present?
      return invalid_parameters unless current_user.has_password?

      current_password      = params[:user][:current_password]
      password              = params[:user][:password]
      password_confirmation = params[:user][:password_confirmation]

      return missing_parameters unless (
        current_password.present? &&
        password.present? &&
        password_confirmation.present?
      )

      user = RegularUser.find_by email: current_user.email # current_user is a `User` not a `RegularUser`
      return invalid_parameters unless user.present?

      if user.authenticate(current_password)
        user.password               = password
        user.password_confirmation  = password_confirmation
        if user.save
          render json: current_user # Render the current_user (uses UserSerializer)
        else
          render json: user.errors, status: :unprocessable_entity
        end
      else
        return invalid_parameters("Current password is incorrect.")
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
      params[:user].try(:delete, :image) # Ember will pass back on save
      params[:user].try(:delete, :has_password) # Ember will pass back on save
      params.require(:user).permit(:name, :email)
    end

  end

end
