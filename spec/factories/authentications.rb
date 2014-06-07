FactoryGirl.define do

  factory :authentication do

    id { SecureRandom.uuid }
    user_id { SecureRandom.uuid }

    uid "12345"
    provider "facebook"
    oauth_token "saldfjlj4a8"
    oauth_expires "2014-04-12 22:20:05"

    trait :facebook do
      provider "facebook"
    end

    trait :google do
      provider "google"
    end

  end

end
