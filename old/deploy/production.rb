set :deploy_env,  -> { "production" }
set :rails_env,   -> { "production" }

# Leave in SSH options - using maintenance.html
role :web, "208.75.74.204", {
  no_release: true,
  user: 'brandon',
  ssh_options: {
    port: 2222
  }
}

# Rails app
role :app, "208.75.74.206", {
  user: 'deploy',
  ssh_options: {
    port: 2222
  }
}

# Set the app server as DB so that migrations get run here. It knows how to talk
# to the DB server.
role :db , "208.75.74.206", {
  primary: true,
  user: 'deploy',
  ssh_options: {
    port: 2222
  }
}

## The actual DB is not used at all by capistrano. Migrations run via app server
# role :db,  "208.75.74.207", {
#   primary: false,
#   no_release: true # Actual DB in case you want to run non-rails specific tasks on it
# }


after "deploy:restart", "notify_slack"

desc "Post into slack channel that we've done a production deployment."
task :notify_slack do
  require 'json'
  require 'faraday'

  puts "\n\n=== Notifying Slack channel of deploy ===\n\n"

  # Not going to try to load up entire rails env here to be able to use `dotenv`. Just hack out the token.
  vars        = File.read(".env").split.map {|line| line.split("=") }
  slack_token = vars.select { |ary| ary[0] == "SLACK_TOKEN" }.first.last

  last_commit_message = `git log --oneline -n 1`

  conn = ::Faraday.new(:url => "https://erpchat.slack.com/services/hooks/incoming-webhook?token=#{slack_token}") do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.response :logger                  # log requests to STDOUT
    faraday.adapter  ::Faraday.default_adapter  # make requests with Net::HTTP
  end

  conn.post do |req|
    req.headers['Content-Type'] = 'application/json'
    post_data = {
      channel:  "#code",
      username: "deploybot",
      text:     "Backend (app.) deployed to production.\nTime: #{Time.now}\nCommit: #{last_commit_message}"
    }
    req.body = post_data.to_json
  end

end
