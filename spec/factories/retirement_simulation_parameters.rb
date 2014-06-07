FactoryGirl.define do

  factory :retirement_simulation_parameters do
    id { SecureRandom.uuid }

    user_is_male true
    married true
    male_age 28
    female_age 29
    user_retired false
    retirement_age_male 62
    retirement_age_female 32
    assets 100000
    expenses_inflation_index 100
    life_insurance 85000
    income 125000
    current_tax_rate 35
    salary_increase 3
    retirement_income 12000
    retirement_expenses 100
    retirement_tax_rate 25
    income_inflation_index 0
    include_home true
    home_value 400000
    sell_house_in 30
    new_home_relative_value 65
    expenses_multiplier 1.6
    fraction_for_single_income 55

    user_id { SecureRandom.uuid }

  end

end
