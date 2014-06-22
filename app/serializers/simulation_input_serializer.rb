class SimulationInputSerializer < ActiveModel::Serializer
  attributes :id, :user_is_male, :married, :male_age, :female_age, :user_retired,
    :retirement_age_male, :retirement_age_female, :assets, :expenses_inflation_index,
    :life_insurance, :income, :current_tax_rate, :salary_increase, :retirement_income,
    :retirement_expenses, :retirement_tax_rate, :income_inflation_index,
    :include_home, :home_value, :sell_house_in, :new_home_relative_value,
    :expenses_multiplier, :fraction_for_single_income
end
