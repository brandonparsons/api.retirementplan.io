class GooglePolicy

  def initialize auth
    @auth = auth
  end

  def first_name
    @auth.info.first_name
  end

  def last_name
    @auth.info.last_name
  end

  def name
    @auth.info.name
  end

  def email
    @auth.info.email
  end

  def username
    nil
  end

  def image_url
    nil
  end

  def uid
    @auth.uid
  end

  def oauth_token
    @auth.credentials.token
  end

  def oauth_expires
    Time.at(@auth.credentials.expires_at)
  end

  def oauth_secret
    @auth.credentials.secret
  end

  def create_callback authentication
    # Place any methods you want to trigger on LinkedIn OAuth creation here.
  end

  def refresh_callback authentication
    # Place any methods you want to trigger on LinkedIn OAuth creation here.
  end

end
