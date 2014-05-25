##
# Not doing this anymore - validating uid & access token via `debug_token` call
##


user_validation_url = "https://graph.facebook.com/me"
conn = get_faraday_connection(user_validation_url)

facebook_response = JSON.parse(conn.get do |req|
  req.params['access_token'] = @access_token
end.body)

raise CustomExceptions::InvalidOauthCredentials unless facebook_response['id'] == @uid
raise CustomExceptions::InvalidOauthCredentials unless facebook_response['email'] == @email
