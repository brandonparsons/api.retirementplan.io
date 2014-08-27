class AddDeletedAtColumns < ActiveRecord::Migration
  def change
    add_column :users,              :deleted_at, :datetime
    add_column :questionnaires,     :deleted_at, :datetime
    add_column :portfolios,         :deleted_at, :datetime
    add_column :expenses,           :deleted_at, :datetime
    add_column :simulation_inputs,  :deleted_at, :datetime
    add_column :authentications,    :deleted_at, :datetime

    add_index :users,             :deleted_at
    add_index :questionnaires,    :deleted_at
    add_index :portfolios,        :deleted_at
    add_index :expenses,          :deleted_at
    add_index :simulation_inputs, :deleted_at
    add_index :authentications,   :deleted_at
  end
end
