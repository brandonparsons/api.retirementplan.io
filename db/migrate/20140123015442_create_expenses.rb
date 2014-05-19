class CreateExpenses < ActiveRecord::Migration
  def change
    create_table :expenses, id: :uuid do |t|
      t.string      :description,       null: false
      t.decimal     :amount,            null: false
      t.string      :frequency,         null: false
      t.datetime    :ends
      t.datetime    :onetime_on
      t.text        :notes,             null: false, default: ""
      t.boolean     :is_added,          null: false, default: false

      t.uuid        :user_id,           null: false
      t.timestamps
    end

    add_index :expenses, :user_id
    add_index :expenses, :is_added
  end
end
