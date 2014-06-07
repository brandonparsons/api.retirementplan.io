FactoryGirl.define do

  factory :expense do

    description "Coffee"
    amount "15"
    frequency "weekly"
    ends "2014-01-22 18:54:42"
    onetime_on nil
    notes "Some miscellaneous notes"
    is_added false

    user_id { SecureRandom.uuid }

    trait :onetime do
      frequency "onetime"
      ends nil
      onetime_on "2014-01-22 18:54:42"
    end

    trait :added do
      is_added true
    end

  end

end
