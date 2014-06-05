module V1

  class PasswordResetsController < ApplicationController
    # No auth required

    def create
      return missing_parameters unless params[:email].present?
      UserMailer.delay.reset_password_instructions(params[:email])
      render json: {success: true, message: "Email being sent to #{params[:email]}"}
    end

    def reset
      token = unescape_token(params)

      ###
      ## For some reason, this can't be pulled into the model.... it fails
      ## every time
      begin
        # This raises an exception if the message is modified
        user_id, timestamp = RegularUser.verifier_for('password-reset').verify(token)
      rescue
        return render json: {success: false, message: "Invalid password reset token."}, status: 422
      end
      ###

      if timestamp_valid?(timestamp)
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


    private

    def timestamp_valid?(timestamp)
      (RegularUser.normalized_timestamp - timestamp) > 1.day
    end

    def unescape_token(params)
      return missing_parameters unless params[:password_reset_token].present?
      return missing_parameters unless params[:password].present?
      return missing_parameters unless params[:password_confirmation].present?

      return CGI.unescape(params[:password_reset_token])
    end

  end

end
