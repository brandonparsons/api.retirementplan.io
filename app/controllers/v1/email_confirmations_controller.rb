module V1

  class EmailConfirmationsController < ApplicationController

    def create
      return missing_parameters unless params[:email].present?
      UserMailer.delay.confirm_email_instructions(email: params[:email], user_id: current_user.try(:id))
      render json: {success: true, message: "Email being sent to #{params[:email]}"}
    end

    def confirm
      return missing_parameters unless params[:email_confirmation_token].present?

      ###
      ## For some reason, this can't be pulled into the model.... it fails
      ## every time
      begin
        # This raises an exception if the message is modified
        user_id, for_email, timestamp = User.verifier_for('email-confirmation').verify(CGI.unescape(params[:email_confirmation_token]))
      rescue
        return render json: {success: false, message: "Invalid email confirmation token."}, status: 422
      end
      ###

      if (RegularUser.normalized_timestamp - timestamp) > 1.day
        return render json: {success: false, message: "That token has expired. Request another token and start over."}, status: 422
      end

      user = User.find(user_id)
      return invalid_parameters unless user.present?

      if user.confirmed? && (user.email == for_email)
        # This was not a change email confirmation, and they are already
        # confirmed. Can short-circuit out without touching DB.
        render json: {success: true, message: 'Your email was already confirmed.'} and return
      end

      if !user.confirmed?
        user.confirm!
        render json: {success: true, message: "Email confirmed."} and return
      elsif user.email != for_email
        user.email = for_email
        if user.save
          render json: {
            success: true,
            message: "Your email address on file has been updated to #{for_email}.",
            updated_email: user.email
          } and return
        else
          render json: user.errors, status: 422 and return
        end
      else
        raise "Invalid logic branching point."
      end
    end

  end

end
