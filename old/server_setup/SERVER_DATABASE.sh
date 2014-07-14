#!/bin/bash

##########################
# POSTGRES SERVER CONFIG #
##########################

# BASE plus....

if [ ! -f /var/.db-config ]; then

  ##############

  if [ -z "$1" ]; then
    echo "Argument not passed - NOT vagrant."
    NOT_VAGRANT=1
  else
    echo "Argument passed - executing for vagrant."
    NOT_VAGRANT=0
  fi

  ##############

  export DEBIAN_FRONTEND=noninteractive

  adduser --gecos "" postgres --disabled-password

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    # External drive mounts for DB data and bacups

    ## Only if the volume is fresh!!
    # mkfs.ext4 /dev/vdc # Might not be vdc... need to check!
    ##

    ## Only if the volume is fresh!!
    # mkfs.ext4 /dev/vdd # Might not be vdd... need to check!
    ###

    mkdir -m 000 /external_volume
    echo "/dev/vdc /external_volume auto noatime 0 0" | tee -a /etc/fstab
    mount /dev/vdc /external_volume

    # Hook up the PG directory first... getting segfaults when trying to move it...
    mkdir -p /external_volume/postgresql
    chown postgres:postgres /external_volume/postgresql
    chmod 0700 /external_volume/postgresql

    ln -s /external_volume/postgresql /var/lib/postgresql

    ###

    mkdir -m 000 /database_backups
    echo "/dev/vdd /database_backups auto noatime 0 0" | tee -a /etc/fstab
    mount /dev/vdd /database_backups
  fi

  ##############

  echo "Installing PostgreSQL...."

  echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  apt-get -qq update && apt-get -y install postgresql-9.3 postgresql-contrib-9.3

  ##############

  service postgresql stop
  mv /etc/init.d/postgresql /etc/init.old.postgresql

  ##############
  #MULTILINE#

  echo 'description "PostgreSQL 9.1 Server"
  author "PostgreSQL"

  start on runlevel [2345]
  stop on runlevel [016]

  respawn

  # setuid postgres
  # setgid postgres

  pre-start script
      if [ -d /var/run/postgresql ]; then
          chmod 2775 /var/run/postgresql
      else
          install -d -m 2775 -o postgres -g postgres /var/run/postgresql
      fi
  end script

  exec su -c "/usr/lib/postgresql/9.3/bin/postgres -D /var/lib/postgresql -c config_file=/etc/postgresql/9.3/main/postgresql.conf" postgres
  ' >> /etc/init/postgresql.conf

  ######

  service postgresql start

  ##############

  #### IF PRODUCTION, NEED TO UPDATE THESE !!!! ####
  ## change 'asdf' to your password in .env.production
  BRANDON_DB_PASSWORD=asdf
  DEPLOY_DB_PASSWORD=asdf

  if [ ${NOT_VAGRANT} -eq 1 ]; then
    echo "************"
    echo "DID YOU CHANGE THE POSTGRES PASSWORD?"
    echo "************"
  fi

  su -c "psql -U postgres -c \"CREATE ROLE brandon WITH SUPERUSER login password '$BRANDON_DB_PASSWORD';\"" postgres
  su -c "psql -U postgres -c \"CREATE ROLE deploy WITH CREATEDB login password '$DEPLOY_DB_PASSWORD';\"" postgres # Need to have createdb for rake db:create

  # Create uuid & hstore extensions on template1 so that all databases get it
  PG_COMMAND="CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
  su -c "psql -U postgres -d template1 -c '$PG_COMMAND'" postgres
  PG_COMMAND="CREATE EXTENSION IF NOT EXISTS \"hstore\";"
  su -c "psql -U postgres -d template1 -c '$PG_COMMAND'" postgres

  ##############

  if [ ${NOT_VAGRANT} -eq 1 ]; then

    ufw allow from 10.0.90.0/24 to any port 5432

    sed -i "s|#listen_addresses = 'localhost'|listen_addresses = '*'|g" /etc/postgresql/9.3/main/postgresql.conf

    echo 'host    all             deploy       10.0.90.0/24            md5' >> /etc/postgresql/9.3/main/pg_hba.conf

    ## PG tuning params ##
    # https://github.com/hw-cookbooks/postgresql #

    # For web DB
    sed -i "s|#checkpoint_segments = 3|checkpoint_segments = 8|g"                       /etc/postgresql/9.3/main/postgresql.conf
    sed -i "s|max_connections = 100|max_connections = 200|g"                            /etc/postgresql/9.3/main/postgresql.conf
    sed -i "s|#checkpoint_completion_target = 0.5|checkpoint_completion_target = 0.7|g" /etc/postgresql/9.3/main/postgresql.conf

    # For a 2056 MB RAM machine
    sed -i "s|shared_buffers = 128MB|shared_buffers = 512MB|g"                /etc/postgresql/9.3/main/postgresql.conf
    sed -i "s|#work_mem = 1MB|work_mem = 10MB|g"                              /etc/postgresql/9.3/main/postgresql.conf
    sed -i "s|#effective_cache_size = 128MB|effective_cache_size = 1542MB|g"  /etc/postgresql/9.3/main/postgresql.conf
    sed -i "s|#maintenance_work_mem = 16MB|maintenance_work_mem = 128MB|g"    /etc/postgresql/9.3/main/postgresql.conf
    ## ##

    # Set up database backups #

    apt-get -y install python-software-properties
    apt-add-repository ppa:brightbox/ruby-ng
    apt-get -qq update && apt-get install -y ruby2.0 ruby2.0-dev

    gem install backup --no-ri --no-rdoc

    mkdir -p /root/Backup
    mkdir -p /root/Backup/models

    #### NEED TO UPDATE THESE!  SEE .env.production ####
    echo "************"
    echo "Did you set the environment variables for DB backups?"
    echo "************"
    echo "\
export DB_SUPERUSER_USER=asdf
export DB_SUPERUSER_PASS=asdf
export S3_DB_BACKUP_USER=asdf
export S3_DB_BACKUP_PASS=asdf
" > /etc/profile.d/backupconfig.sh
    chmod +x /etc/profile.d/backupconfig.sh
    #####


    ##############
    #MULTILINE#

    echo "\
# encoding: utf-8

##
# Backup v4.x Configuration
#
# Documentation: http://meskyanichi.github.io/backup
# Issue Tracker: https://github.com/meskyanichi/backup/issues

##
# Config Options
#
# The options here may be overridden on the command line, but the result
# will depend on the use of --root-path on the command line.
#
# If --root-path is used on the command line, then all paths set here
# will be overridden. If a path (like --tmp-path) is not given along with
# --root-path, that path will use it's default location _relative to --root-path_.
#
# If --root-path is not used on the command line, a path option (like --tmp-path)
# given on the command line will override the tmp_path set here, but all other
# paths set here will be used.
#
# Note that relative paths given on the command line without --root-path
# are relative to the current directory. The root_path set here only applies
# to relative paths set here.
#
# ---
#
# Sets the root path for all relative paths, including default paths.
# May be an absolute path, or relative to the current working directory.
#
# root_path 'my/root'
#
# Sets the path where backups are processed until they're stored.
# This must have enough free space to hold apx. 2 backups.
# May be an absolute path, or relative to the current directory or +root_path+.
#
# tmp_path  'my/tmp'
#
# Sets the path where backup stores persistent information.
# When Backup's Cycler is used, small YAML files are stored here.
# May be an absolute path, or relative to the current directory or +root_path+.
#
# data_path 'my/data'

##
# Utilities
#
# If you need to use a utility other than the one Backup detects,
# or a utility can not be found in your \$PATH.
#
#   Utilities.configure do
#     tar       '/usr/bin/gnutar'
#     redis_cli '/opt/redis/redis-cli'
#   end

##
# Logging
#
# Logging options may be set on the command line, but certain settings
# may only be configured here.
#
#   Logger.configure do
#     console.quiet     = true            # Same as command line: --quiet
#     logfile.max_bytes = 2_000_000       # Default: 500_000
#     syslog.enabled    = true            # Same as command line: --syslog
#     syslog.ident      = 'my_app_backup' # Default: 'backup'
#   end
#
# Command line options will override those set here.
# For example, the following would override the example settings above
# to disable syslog and enable console output.
#   backup perform --trigger my_backup --no-syslog --no-quiet

##
# Component Defaults
#
# Set default options to be applied to components in all models.
# Options set within a model will override those set here.
#
#   Storage::S3.defaults do |s3|
#     s3.access_key_id     = 'my_access_key_id'
#     s3.secret_access_key = 'my_secret_access_key'
#   end
#
#   Notifier::Mail.defaults do |mail|
#     mail.from                 = 'sender@email.com'
#     mail.to                   = 'receiver@email.com'
#     mail.address              = 'smtp.gmail.com'
#     mail.port                 = 587
#     mail.domain               = 'your.host.name'
#     mail.user_name            = 'sender@email.com'
#     mail.password             = 'my_password'
#     mail.authentication       = 'plain'
#     mail.encryption           = :starttls
#   end

##
# Preconfigured Models
#
# Create custom models with preconfigured components.
# Components added within the model definition will
# +add to+ the preconfigured components.
#
#   preconfigure 'MyModel' do
#     archive :user_pictures do |archive|
#       archive.add '~/pictures'
#     end
#
#     notify_by Mail do |mail|
#       mail.to = 'admin@email.com'
#     end
#   end
#
#   MyModel.new(:john_smith, 'John Smith Backup') do
#     archive :user_music do |archive|
#       archive.add '~/music'
#     end
#
#     notify_by Mail do |mail|
#       mail.to = 'john.smith@email.com'
#     end
#   end

Database::PostgreSQL.defaults do |db|
  db.username = ENV['DB_SUPERUSER_USER']
  db.password = ENV['DB_SUPERUSER_PASS']
end

Storage::S3.defaults do |s3|
  s3.access_key_id      = ENV['S3_DB_BACKUP_USER']
  s3.secret_access_key  = ENV['S3_DB_BACKUP_PASS']
end
" > /root/Backup/config.rb

    ##########


    ##############
    #MULTILINE#

    echo "\
# To run backup:
# $ backup perform -t db_server_backup
# (Uses default config file location)
#

Model.new(:db_server_backup, 'Backs up critical content on RP database server') do

  split_into_chunks_of 5000 # MB
  compress_with Gzip

  time = Time.now
  if time.day == 1  # first day of the month
    storage_id = :monthly
    keep = 2
    skip_tables = []
  elsif time.sunday?
    storage_id = :weekly
    keep = 3
    skip_tables = []
  else
    storage_id = :daily
    keep = 7
    skip_tables = []
    # skip_tables = ['efficient_frontiers', 'efficient_frontiers_portfolios', 'portfolios', 'portfolios_securities']
  end

  database PostgreSQL do |db|
    # To dump all databases, set 'db.name = :all' (or leave blank)
    # When dumping all databases, 'skip_tables' and 'only_tables' are ignored.

    db.name               = 'rp_production'
    db.host               = 'localhost'
    db.port               = 5432
    db.additional_options = ['-xc', '-E=utf8']
    db.skip_tables        = skip_tables

    ## In defaults config
    # db.username         = 'my_username'
    # db.password         = 'my_password'

    ## Not using
    # db.socket           = '/tmp/pg.sock'
    # db.only_tables      = ['only', 'these', 'tables']
  end

  # Someone did the work for OpenStack storage, but maintainer is currently not
  # merging.... Maybe consider manually applying patch sometime?
  # https://github.com/benmccann/backup/commit/a48487c5e613ef27fe6e19b5645a512757e2b13c
  store_with S3 do |s3|
    s3.region = 'us-west-2'
    s3.bucket = 'retirementplan'
    s3.path   = \"db_backups/#{storage_id}\"
    s3.storage_class = :reduced_redundancy
    s3.keep   = keep
  end

  # local storage wants to be last
  store_with Local do |local|
    local.path = \"/database_backups/#{storage_id}\"
    local.keep = keep
  end

end
" > /root/Backup/models/db_server_backup.rb

    ###########

    ## into crontab:
    # crontab -e
    # 0 5 * * * 'source /etc/profile.d/backupconfig.sh; /usr/local/bin/backup perform -t db_server_backup'
    echo "Did you set up crontab for db backups?"
  fi

  service postgresql restart

  ##############


  touch /var/.db-config
fi
