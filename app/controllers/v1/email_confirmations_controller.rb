module V1

  class EmailConfirmationsController < ApplicationController
    # No auth required

    def create
      return missing_parameters unless params[:email].present?
      UserMailer.delay.confirm_email_instructions(params[:email])
      render json: {success: true, message: "Email being sent to #{params[:email]}"}
    end

    def confirm
      token = unescape_token(params)

      ###
      ## For some reason, this can't be pulled into the model.... it fails
      ## every time
      begin
        # This raises an exception if the message is modified
        user_id, timestamp = RegularUser.verifier_for('email-confirmation').verify(token)
      rescue
        return render json: {success: false, message: "Invalid email confirmation token."}, status: 422
      end
      ###

      if timestamp_valid?(timestamp)
        return render json: {success: false, message: "That token has expired. Request another token and start over."}, status: 422
      end

      user = User.find(user_id)
      return invalid_parameters unless user.present?

      if user.confirmed?
        render json: {success: true, message: 'Your email was already confirmed.'}
      else
        user.confirm
        if user.save
          render json: {success: true, message: 'Email confirmed.'}
        else
          render json: user.errors, status: 422
        end
      end
    end


    private

    def timestamp_valid?(timestamp)
      (RegularUser.normalized_timestamp - timestamp) > 1.day
    end

    def unescape_token(params)
      return missing_parameters unless params[:email_confirmation_token].present?
      return CGI.unescape(params[:email_confirmation_token])
    end

  end

end
