require 'securerandom'

module AnalyticsTracker

  extend self

  def track_user_sign_up(user_id: , analytics_client_id: SecureRandom.uuid)
    # We are no longer doing redirect/location.href trickery on the marketing
    # site to ensure conversions are marked for user sign ups. Post to the www
    # site's google analytics to register a conversion from the server. This is
    # arguably better as we know for sure a user was created.

    # Don't post anything in test/dev....
    return false unless tracking_enabled?

    puts "Posting to analytics for user creation. UserID: #{user_id} || ClientID: #{analytics_client_id}"
    post_action_to_marketing_property(analytics_client_id, {
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

  def post_action_to_marketing_property(analytics_client_id, data_hash)
    # If you wanted to post to the "app" analytics property, you would just use
    # ENV['GA_TRACKING_CODE']

    base_data = {
      v:    1,
      tid:  ENV['GA_TRACKING_CODE_MARKETING_SITE'],
      cid:  analytics_client_id
    }
    http_conn.post '/collect', base_data.merge(data_hash)
  end

  def http_conn
    Faraday.new(url: 'https://www.google-analytics.com')
  end

end
