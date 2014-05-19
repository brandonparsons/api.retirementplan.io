class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    handle_oauth 'Facebook'
  end

  def amazon
    handle_oauth 'Amazon'
  end

  def google
    handle_oauth "Google"
  end

  def linkedin
    handle_oauth "LinkedIn"
  end


  private

  def handle_oauth(kind)
    omniauth_hash = request.env["omniauth.auth"]

    oauth = OAuthUser.new(omniauth_hash, current_user)
    begin
      oauth.login_or_create
    rescue CustomExceptions::UserExistsWithPassword
      flash[:error] = "An account already exists for that email using password registration. Please log in first."
      redirect_to new_user_session_path and return
    rescue CustomExceptions::UserExistsFromOauth => e
      provider = e.message
      flash[:error] = "An account already exists for that email (try #{provider}). You need to log in before you can add additional providers."
      redirect_to new_user_session_path and return
    end
    sign_in_and_redirect oauth.user, event: :authentication
  end

end
