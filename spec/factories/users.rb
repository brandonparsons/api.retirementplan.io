FactoryGirl.define do

  # sequence(:email) { |n| "test-person-#{n}@test.com" }
  # sequence(:name) { |n| "Test Person #{n}" }

  # after(:stub, :create) { |user| user.confirmed_at = Time.zone.now }

  factory :user do

    id { SecureRandom.uuid }

    email { Faker::Internet.email }

    name do
      name = Faker::Name.first_name + " " + Faker::Name.last_name
      name[0...20]
    end

    max_contact_frequency 7.days
    min_rebalance_spacing 90.days
    allowable_drift 5

    # password "asdfasdf" # Don't change the base password - hard coded into some feature specs
    # password_confirmation "asdfasdf"

    from_oauth false

    trait :confirmed do
      confirmed_at { Time.zone.now }
    end

    trait :admin do
      admin true
    end

    trait :from_oauth do
      from_oauth true
    end

  end


  factory :user_with_facebook_authentication do
    after(:create) do |instance|
      authentication = create(:authentication, :facebook)
      instance.authentications << authentication
    end
  end

  factory :user_with_google_authentication do
    after(:create) do |instance|
      authentication = create(:authentication, :google)
      instance.authentications << authentication
    end
  end

end # Define block
