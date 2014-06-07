set :deploy_env,  -> { "staging" }
set :rails_env,   -> { "staging" }

set :update_deploy_tags, false
set :update_deploy_timestamp_tags, false


server '192.168.1.150', :web, :app, :db, {
  primary: true,
  user: 'deploy'
}
