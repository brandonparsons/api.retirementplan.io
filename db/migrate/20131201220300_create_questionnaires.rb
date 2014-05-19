class CreateQuestionnaires < ActiveRecord::Migration
  def change
    create_table :questionnaires, id: :uuid do |t|
      t.float   :pratt_arrow_low,               null: false
      t.float   :pratt_arrow_high,              null: false

      t.integer :age,                           null: false
      t.integer :sex,                           null: false
      t.integer :no_people,                     null: false
      t.integer :real_estate_val,               null: false
      t.integer :saving_reason,                 null: false
      t.integer :investment_timeline,           null: false
      t.integer :investment_timeline_length,    null: false
      t.integer :economy_performance,           null: false
      t.integer :financial_risk,                null: false
      t.integer :credit_card,                   null: false
      t.integer :pension,                       null: false
      t.integer :inheritance,                   null: false
      t.integer :bequeath,                      null: false
      t.integer :degree,                        null: false
      t.integer :loan,                          null: false
      t.integer :forseeable_expenses,           null: false
      t.integer :married,                       null: false
      t.integer :emergency_fund,                null: false
      t.integer :job_title,                     null: false
      t.integer :investment_experience,         null: false

      t.uuid    :user_id,                       null: false
      t.timestamps
    end

    add_index :questionnaires, :user_id, unique: true
  end
end
