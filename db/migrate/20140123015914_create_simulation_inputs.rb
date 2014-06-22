class CreateSimulationInputs < ActiveRecord::Migration
  def change
    create_table :simulation_inputs, id: :uuid do |t|
      # Some of these technically could use `null: false` constraints, but the
      # logic is fairly complex. Will enforce at the application level.

      t.boolean :user_is_male
      t.boolean :married
      t.integer :male_age
      t.integer :female_age
      t.boolean :user_retired
      t.integer :retirement_age_male
      t.integer :retirement_age_female
      t.decimal :assets
      t.decimal :expenses_inflation_index
      t.decimal :life_insurance
      t.decimal :income
      t.decimal :current_tax_rate
      t.decimal :salary_increase
      t.decimal :retirement_income
      t.decimal :retirement_expenses
      t.decimal :retirement_tax_rate
      t.decimal :income_inflation_index
      t.boolean :include_home
      t.decimal :home_value
      t.decimal :sell_house_in
      t.decimal :new_home_relative_value
      t.decimal :expenses_multiplier
      t.decimal :fraction_for_single_income

      t.uuid    :user_id, null: false
      t.timestamps
    end

    add_index :simulation_inputs, :user_id, unique: true
  end
end
