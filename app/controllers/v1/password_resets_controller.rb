module V1

  class PasswordResetsController < ApplicationController

    def create
      return missing_parameters unless params[:email].present?
      return render json: {success: false, message: "That is an invalid email address"}, status: 422 unless /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(params[:email])
      ResetPasswordInstructionsSender.new.async.perform(params[:email])
      render json: {success: true, message: "Email being sent to #{params[:email]}"}
    end

    def reset
      return missing_parameters unless params[:password_reset_token].present?
      return missing_parameters unless params[:password].present?
      return missing_parameters unless params[:password_confirmation].present?

      ###
      ## For some reason, this can't be pulled into the model.... it fails
      ## every time
      begin
        # This raises an exception if the message is modified
        user_id, timestamp = RegularUser.verifier_for('password-reset').verify(CGI.unescape(params[:password_reset_token]))
      rescue
        return render json: {success: false, message: "Invalid password reset token."}, status: 422
      end
      ###

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

  end

end
