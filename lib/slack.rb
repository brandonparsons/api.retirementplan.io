class Slack
  def initialize(organization = "retirementplan", token = ENV['SLACK_TOKEN'])
    @token  = token
    @url    = "https://#{organization}.slack.com/services/hooks/incoming-webhook?token=#{token}"
  end

  def post_message(message: , attachments: nil, channel: '#bot-notifications', username: 'retirementplan-bot')
    payload = {
      text:     message,
      channel:  channel,
      username: username,
      # icon_url: "https://www.yapp.us/images/yappie_48.gif" ## Defaulting to ghost emoji
    }
    if attachments
      payload[:attachments] = attachments
    end

    conn = Faraday.new(:url => @url) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    if !@token
      Rails.logger.warn("No token was provided for slack posting, so we will skip it. Payload was: " + payload.to_json)
    else
      conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end
    end
  end
end
