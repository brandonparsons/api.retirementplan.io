require 'securerandom'

class AnalyticsTracker

  def initialize(client_id=SecureRandom.uuid)
    @client_id = client_id
  end

  def track_user_sign_up(user_id)
    # We are no longer doing redirect/location.href trickery on the marketing
    # site to ensure conversions are marked for user sign ups. Post to the www
    # site's google analytics to register a conversion from the server. This is
    # arguably better as we know for sure a user was created.
    return false unless tracking_enabled?

    post_event({
      uid:  user_id,
      t:    'event',
      ec:   'conversion',
      ea:   'signup'
    })
    return true
  end


  private

  def tracking_enabled?
    Rails.env.production?
  end

  def post_event(data_hash)
    base_data = {
      v:    1,
      tid:  ENV['GA_TRACKING_CODE_MARKETING_SITE'],
      cid:  @client_id
    }
    http_conn.post '/collect', base_data.merge(data_hash)
  end

  def http_conn
    Faraday.new(url: 'https://www.google-analytics.com')
  end

end
