class AdminNotifier
  include SuckerPunch::Job

  def perform(notification_type, user_id=nil)
    ActiveRecord::Base.connection_pool.with_connection do
      message = "Default message - none set :("
      if notification_type == "new_user"
        user = User.find(user_id)
        message = "New user signup! #{user.name}: #{user.email}"
      end
      Slack.new.post_message(message: message)
    end
  end

end

# attachments = []
# experiment.alternatives.each do |alternative|
#   attachments.push({
#     fallback: "Experiment data not shown in this client.",
#     pretext: "Alternative status:",
#     color: alternative.to_s == experiment.winner.to_s ? "good" : "#222222",
#     fields: [
#       {
#         title: "Alternative",
#         value: alternative.name,
#         short: true
#       },
#       {
#         title: "Participants",
#         value: alternative.participant_count,
#         short: true
#       },
#       {
#         title: "Completed",
#         value: alternative.completed_count,
#         short: true
#       },
#       {
#         title: "Conversion Rate",
#         value: conversion_rate(alternative, experiment),
#         short: true
#       },
#       {
#         title: "Confidence",
#         value: confidence_level(alternative.z_score),
#         short: true
#       }
#     ]
#   })
# end
