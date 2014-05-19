class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios, id: :uuid do |t|
      t.decimal :expected_return,             null: false
      t.decimal :expected_std_dev,            null: false
      t.json    :weights,                     null: false, default: {}
      t.json    :prettified_weights,          null: false, default: {}

      t.hstore  :data

      t.uuid    :user_id,                     null: false
      t.timestamps
    end

    add_index :portfolios, :user_id,  unique: true
    add_index :portfolios, :data,     using: :gin
  end
end
