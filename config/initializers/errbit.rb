if Rails.env.production? || Rails.env.staging?
  raise "Missing AIRBRAKE_KEY"  unless ENV['AIRBRAKE_KEY']
  raise "Missing AIRBRAKE_HOST" unless ENV['AIRBRAKE_HOST']

  Airbrake.configure do |config|
    config.api_key  = ENV['AIRBRAKE_KEY']
    config.host     = ENV['AIRBRAKE_HOST']
    config.port     = 443
    config.secure   = config.port == 443
    config.async do |notice|
      AirbrakeDeliveryWorker.perform_async(notice.to_xml)
    end
    config.user_attributes = [:id, :name, :email]
  end
end
