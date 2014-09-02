class RemoveSomeDeletedAtColumns < ActiveRecord::Migration
  def change
    remove_column :questionnaires,    :deleted_at
    remove_column :portfolios,        :deleted_at
    remove_column :expenses,          :deleted_at
    remove_column :simulation_inputs, :deleted_at
    remove_column :authentications,   :deleted_at
  end
end
