module V1

  class UsersController < ApplicationController
    before_action :authenticate_user!, except: [:create]

    def create
      @user = RegularUser.new(user_create_params)
      if @user.save
        @user.sign_in!
        UserCreator.new(@user.id, @user.email).call
        render json: UserSerializer.new(@user).as_json, status: 201
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    end

    def show
      render json: current_user if stale?(current_user)
    end

    def update
      ## This update method will only work if the user has a password - i.e. if
      ## the user was created from OAuth, they will need to set a password before
      ## they can change their name/email.
      return invalid_parameters unless current_user.has_password?

      # Validate the current password
      return missing_parameters unless params[:user][:current_password].present?
      user = RegularUser.find_from_all_users_with_id current_user.id # current_user is a `User` not a `RegularUser`
      return invalid_parameters("Current password is incorrect.") unless user.authenticate(params[:user][:current_password])

      # After validation, don't want this in the params
      params[:user].delete(:current_password)

      # If the email has changed, kick off 'reconfirmable' flow
      if params[:user][:email].present? && (params[:user][:email] != user.email)
        unconfirmed_email = params[:user][:email]
        UserMailer.delay.confirm_email_instructions(email: unconfirmed_email, user_id: current_user.id)
        params[:user].delete(:email) # Remove because we are not updating at this time
      end

      # Update the user. This will work with pass/pass_conf
      if user.update_attributes(user_update_params)
        user_data = UserSerializer.new(user).as_json
        user_data.merge!({unconfirmed_email: unconfirmed_email}) if unconfirmed_email
        render json: user_data, status: :ok
      else
        render json: user.errors, status: :unprocessable_entity
      end
    end

    def create_password
      email = current_user.email
      UserMailer.delay.reset_password_instructions(email, set_password_request: true)
      render json: {success: true, message: "Email being sent to #{email} with instructions on how to set a password."}
    end

    def preferences
      # Returns the user's preferences for the edit page
      render json: {
        user_preferences: [
          current_user.slice(:allowable_drift, :max_contact_frequency, :min_rebalance_spacing).merge({id: 'singleton'})
        ]
      }
    end

    def set_preferences
      # Sets the user's preferences from a save on the edit page
      if current_user.update_attributes(user_preference_params)
        render json: {
          user_preferences: [
            current_user.slice(:allowable_drift, :max_contact_frequency, :min_rebalance_spacing).merge({id: 'singleton'})
          ]
        }
      else
        render json: current_user.errors, status: :unprocessable_entity
      end
    end

    def accept_terms
      current_user.accept_terms!
      render json: {success: true, message: "Term acceptance saved."}
    end


    private

    def user_create_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def user_update_params
      params.require(:user).permit(:name, :email, :current_password, :password, :password_confirmation)
    end

    def user_preference_params
      params.require(:user_preference).permit(:allowable_drift, :max_contact_frequency, :min_rebalance_spacing)
    end

  end

end
