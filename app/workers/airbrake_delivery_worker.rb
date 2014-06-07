class AirbrakeDeliveryWorker
  include Sidekiq::Worker
  include Airbrake

  def perform(notice)
    puts "[WORKER][AirbrakeDeliveryWorker]: Sending error..."
    Airbrake.sender.send_to_airbrake notice
    puts "[WORKER][AirbrakeDeliveryWorker]: Done."
  end
end
