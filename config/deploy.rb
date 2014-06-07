# Initial Deployment: cap (production|staging) deploy:initial

require 'bundler/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano/deploy/tagger'


def get_binding
  binding # So that everything can be used in templates generated for the servers
end

def from_template(file)
  require 'erb'
  template = File.read(File.join(File.dirname(__FILE__), "..", file))
  result = ERB.new(template).result(self.get_binding)
end


#################
# CONFIGURATION #
#################

set :application,   "retirementplan" # This needs to be the same as configured in bin/foreman_export_upstart
set :stages,        %w(production staging)
set :default_stage, "staging"

set :user,      -> { "deploy" }
set :group,     -> { "deploy" }
set :use_sudo, false

set :scm,         :git
set :scm_verbose, true
set :branch,      'master'
set :repository,  'git@bitbucket.org:retirementplanio/api.retirementplan.io.git'

default_run_options[:pty]   = true
ssh_options[:forward_agent] = true

set :deploy_to,   "/opt/apps/retirementplan.io"
set :deploy_via,  :remote_cache

set :bundle_dir, '~/shared'

set :rake, 'bundle exec rake'

set :normalize_asset_timestamps,  false
set :assets_role,                 [:web, :app, :worker]


##################
# SCHEDULE TASKS #
##################

before  'deploy',                   'upload_secrets'
after   'deploy:finalize_update',   'deploy:additional_symlinks'
after   'deploy:restart',           'deploy:cleanup' # Clean up old releases on each deploy


#########
# TASKS #
#########

desc "Uploads secrets to server"
task :upload_secrets, roles: :app do
  upload("config/application.yml", "#{shared_path}/application.yml")
end


namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, roles: :app do
    run "cd #{current_path} && #{sudo} bin/foreman_export_upstart"
  end

  desc "Start the application services"
  task :start, roles: :app do
    run "#{sudo} service #{application} start"
  end

  desc "Stop the application services"
  task :stop, roles: :app do
    run "#{sudo} service #{application} stop"
  end

  desc "Restart the application services"
  task :restart, roles: :app do
    run "#{sudo} service #{application} start || #{sudo} service #{application} restart"
  end
end


namespace :deploy do

  # ---------------------- #
  # Over-ride Cap Defaults #
  # ---------------------- #

  task :start, roles: :app do
    foreman.export
    foreman.start
  end

  task :restart, roles: :app do
    foreman.export
    run "#{sudo} #{current_path}/bin/puma_phased_restart"
    # Uncomment this (and comment line above) if making changes to the procfile:
    # foreman.restart
  end

  namespace :web do
    desc "Enable maintenance mode. Set ENV['DURATION'] (in MINTUES) to estimate a downtime for the page."
    task :disable, roles: :web do
      set(:went_down_at) { Time.now.strftime("%B %e, %Y at %r %Z") }
      set(:expected_duration) { ENV['DURATION'] || ENV['DOWNTIME'] || nil }
      maintenance_page = from_template("config/deploy/templates/maintenance.html.erb")
      put maintenance_page, "/var/www/public/maintenance.html"
    end

    desc "Disable maintenance mode"
    task :enable, roles: :web do
      run "rm /var/www/public/maintenance.html"
    end
  end


  # --------------------- #
  # Custom Deploy Methods #
  # --------------------- #

  desc "Executes the initial procedures for deploying a Ruby on Rails Application."
  task :initial do
    system "cap #{fetch :stage} deploy:setup"
    system "cap #{fetch :stage} upload_secrets"
    system "cap #{fetch :stage} deploy:update"
    system "cap #{fetch :stage} deploy:db:create"
    system "cap #{fetch :stage} deploy:db:migrate"
    system "cap #{fetch :stage} deploy:db:seed"
    system "cap #{fetch :stage} deploy:start"
  end

  desc "Symlink shared configs and folders on each release."
  task :additional_symlinks, roles: :app do
    puts "\n\n=== Symlinking shared files ===\n\n"
    run "ln -nfs #{shared_path}/application.yml #{release_path}/config/application.yml"
  end

  namespace :db do
    desc "Create Production Database"
    task :create, roles: :db, only: {primary: true} do
      puts "\n\n=== Creating the Production Database! ===\n\n"
      run "cd #{current_path}; RAILS_ENV=#{deploy_env} #{rake} db:create"
    end

    desc "Migrate Production Database"
    task :migrate, roles: :db, only: {primary: true} do
      puts "\n\n=== Migrating the Production Database! ===\n\n"
      run "cd #{current_path}; RAILS_ENV=#{deploy_env} #{rake} db:migrate"
    end

    desc "Populates the Production Database"
    task :seed, roles: :db, only: {primary: true} do
      puts "\n\n=== Populating the Production Database! ===\n\n"
      run "cd #{current_path}; RAILS_ENV=#{deploy_env} #{rake} db:seed"
    end
  end # namespace `db`

end # namespace `deploy`
