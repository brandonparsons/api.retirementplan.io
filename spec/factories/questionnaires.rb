FactoryGirl.define do

  factory :questionnaire do

    user_id { SecureRandom.uuid }
    id { SecureRandom.uuid }

    # This is going to be a fairly conservative person - married, house, older
    age 65
    sex 1
    no_people 4
    real_estate_val 5
    saving_reason 0
    investment_timeline 1
    investment_timeline_length 0
    economy_performance 1
    financial_risk 1
    credit_card 1
    pension 3
    inheritance 1
    bequeath 0
    degree 3
    loan 1
    forseeable_expenses 0
    married 1
    emergency_fund 2
    job_title 1
    investment_experience 1

    trait :aggressive do
      age 20
      no_people 1
      real_estate_val 6
      investment_timeline 0
      investment_timeline_length 1
      economy_performance 0
      financial_risk 0
      pension 4
      inheritance 4
      investment_experience 3
    end

  end
end
