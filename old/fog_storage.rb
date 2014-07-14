require 'fog'

# # Need to do this on Mac, hopefully not on linux boxes
# Excon.defaults[:ssl_verify_peer] = false

service = Fog::Storage.new({
    provider:           'OpenStack',                # OpenStack Fog provider
    openstack_username: ENV['OPENSTACK_USERNAME'],  # Your OpenStack Username
    openstack_api_key:  ENV['OPENSTACK_PASSWORD'],  # Your OpenStack Password
    openstack_region:   'alberta',
    openstack_auth_url: 'http://nova-ab.dair-atir.canarie.ca:5000/v2.0/tokens'
})

bucket = service.directories.get 'database_backups'


## Uploading a small file (< 5GB) ##
# upload_small_file bucket, 'test.txt', File.open("/tmp/test.txt")
def upload_small_file(bucket, key, body)
  bucket.files.create key: key, body: body
end


## Splitting a file into chunks (max 5 GB) ##
# split_and_upload service, "/path/to/big/file", "bigfile-001", "database_backups"

SEGMENT_LIMIT = 5368709119.0  # 5GB -1
BUFFER_SIZE = 1024 * 1024 # 1MB

def split_and_upload(service, source_file_path, file_name, bucket_name)

  # Split into chunks, upload to Openstack
  File.open(source_file_path) do |f|
    segment = 0
    until file.eof?
      segment += 1
      offset = 0

      # upload segment to cloud files
      segment_suffix = segment.to_s.rjust(10, '0')
      service.put_object(bucket_name, "#{file_name}/#{segment_suffix}", nil) do
        if offset <= SEGMENT_LIMIT - BUFFER_SIZE
          buf = file.read(BUFFER_SIZE).to_s
          offset += buf.size
          buf
        else
          ''
        end
      end
    end
  end

  # write manifest file
  service.put_object_manifest(bucket_name, file_name, 'X-Object-Manifest' => "#{bucket_name}/#{file_name}/")
end
