## ~/Backup/config.rb

# Database::PostgreSQL.defaults do |db|
#   db.username = xxxxxxx
#   db.password = xxxxxxx
# end

# Notifier::HttpPost.defaults do |post|
#   post.uri = 'https://erpchat.slack.com/services/hooks/incoming-webhook?token=xxxxxxxxx'
# end

# ENV['OPENSTACK_PASSWORD']  = xxxxxxx
# ENV['OPENSTACK_USERNAME']  = xxxxxxx

## To run backup:
# $ backup perform -t db_server_backup
# (Uses default config file location)
#

Model.new(:db_server_backup, 'Backs up critical content on ERP database server') do

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
    skip_tables = ["efficient_frontiers", "efficient_frontiers_portfolios", "portfolios", "portfolios_securities"]
  end

  database PostgreSQL do |db|
    # To dump all databases, set `db.name = :all` (or leave blank)
    # When dumping all databases, `skip_tables` and `only_tables` are ignored.

    db.name               = "erp_production"
    db.host               = "localhost"
    db.port               = 5432
    db.additional_options = ["-xc", "-E=utf8"]
    db.skip_tables        = skip_tables

    ## In defaults config
    # db.username         = "my_username"
    # db.password         = "my_password"

    ## Not using
    # db.socket           = "/tmp/pg.sock"
    # db.only_tables      = ["only", "these", "tables"]
  end

  # Someone did the work for OpenStack storage, but maintainer is currently not
  # merging.... Maybe consider manually applying patch sometime?
  # https://github.com/benmccann/backup/commit/a48487c5e613ef27fe6e19b5645a512757e2b13c
  store_with Local do |local|
    local.path = "/database_backups/#{storage_id}"
    local.keep = keep
  end

  after do |exit_status|
    if exit_status == 0
      require 'fog'

      service = Fog::Storage.new({
          provider:           'OpenStack',                # OpenStack Fog provider
          openstack_username: ENV['OPENSTACK_USERNAME'],  # Your OpenStack Username
          openstack_api_key:  ENV['OPENSTACK_PASSWORD'],  # Your OpenStack Password
          openstack_region:   'alberta',
          openstack_auth_url: 'http://nova-ab.dair-atir.canarie.ca:5000/v2.0/tokens'
      })

      bucket = service.directories.get 'db_server_backups'

      bucket.files.create key: "test-#{Time.now.hour}.txt", body: 'hello there!'

      # SEGMENT_LIMIT = 5368709119.0  # 5GB -1
      # BUFFER_SIZE = 1024 * 1024 # 1MB
      # def split_and_upload(service, source_file_path, file_name, bucket_name)

      #   # Split into chunks, upload to Openstack
      #   File.open(source_file_path) do |f|
      #     segment = 0
      #     until file.eof?
      #       segment += 1
      #       offset = 0

      #       # upload segment to cloud files
      #       segment_suffix = segment.to_s.rjust(10, '0')
      #       service.put_object(bucket_name, "#{file_name}/#{segment_suffix}", nil) do
      #         if offset <= SEGMENT_LIMIT - BUFFER_SIZE
      #           buf = file.read(BUFFER_SIZE).to_s
      #           offset += buf.size
      #           buf
      #         else
      #           ''
      #         end
      #       end
      #     end
      #   end

      #   # write manifest file
      #   service.put_object_manifest(bucket_name, file_name, 'X-Object-Manifest' => "#{bucket_name}/#{file_name}/")
      # end

    end
  end

  notify_by HttpPost do |post|
    post.on_success = false
    post.on_warning = true
    post.on_failure = true
    # post.uri = 'http://.....' ## Set up for Slack in defaults
    require 'json'
    post.params = {
      payload: {
        channel: '#notifications',
        username: "backupbot",
        text:     "*******\nBACKUP FAILED\n**********"
      }.to_json
    }
  end

  notify_by HttpPost do |post|
    post.on_success = true
    post.on_warning = false
    post.on_failure = false

    require 'json'
    post.params = {
      payload: {
        channel: '#notifications',
        username: "backupbot",
        text:     "Backup success"
      }.to_json
    }
  end

end



# ##
# # Archive [Archive]
# ##

# # Adding a file or directory (including sub-directories):
# #   archive.add "/path/to/a/file.rb"
# #   archive.add "/path/to/a/directory/"
# #
# # Excluding a file or directory (including sub-directories):
# #   archive.exclude "/path/to/an/excluded_file.rb"
# #   archive.exclude "/path/to/an/excluded_directory
# #
# # By default, relative paths will be relative to the directory
# # where `backup perform` is executed, and they will be expanded
# # to the root of the filesystem when added to the archive.
# #
# # If a `root` path is set, relative paths will be relative to the
# # given `root` path and will not be expanded when added to the archive.
# #
# #   archive.root '/path/to/archive/root'
# #

# archive :test_archive do |archive|
#   # Run the `tar` command using `sudo`
#   # archive.use_sudo
#   # archive.add "/path/to/a/folder/"
#   # archive.exclude "/path/to/a/excluded_file.rb"
#   # archive.exclude "/path/to/a/excluded_folder"
# end

# ##
# # Mail [Notifier]
# ##

# # The default delivery method for Mail Notifiers is 'SMTP'.
# # See the documentation for other delivery options.
# #
# notify_by Mail do |mail|
#   mail.on_success           = true
#   mail.on_warning           = true
#   mail.on_failure           = true

#   mail.from                 = "sender@email.com"
#   mail.to                   = "receiver@email.com"
#   mail.address              = "smtp.gmail.com"
#   mail.port                 = 587
#   mail.domain               = "your.host.name"
#   mail.user_name            = "sender@email.com"
#   mail.password             = "my_password"
#   mail.authentication       = "plain"
#   mail.encryption           = :starttls
# end

# ##
# # Twitter [Notifier]
# ##

# notify_by Twitter do |tweet|
#   tweet.on_success = true
#   tweet.on_warning = true
#   tweet.on_failure = true

#   tweet.consumer_key       = "my_consumer_key"
#   tweet.consumer_secret    = "my_consumer_secret"
#   tweet.oauth_token        = "my_oauth_token"
#   tweet.oauth_token_secret = "my_oauth_token_secret"
# end

# notify_by HttpPost do |post|
#   post.on_success = true
#   post.on_warning = true
#   post.on_failure = true

#   # URI to post the notification to.
#   # Port may be specified if needed.
#   # If Basic Authentication is required, supply user:pass.
#   # post.uri = 'http://something.com'

#   ##
#   # Optional
#   #
#   # Additional headers to send.
#   # post.headers = { 'Authentication' => 'my_auth_info' }
#   #
#   # Additional form params to post.
#   # post.params = { }
#   #
#   # Successful response codes. Default: 200
#   # post.success_codes = [200, 201, 204]
#   #
#   # Defaults to true on most systems.
#   # Force with +true+, disable with +false+
#   # post.ssl_verify_peer = false
#   #
#   # Supplied by default. Override with a custom 'cacert.pem' file.
#   # post.ssl_ca_file = '/my/cacert.pem'
# end
