class CreatePortfolios < ActiveRecord::Migration
  def change
    create_table :portfolios, id: :uuid do |t|
      t.hstore  :hstore_data

      t.uuid    :user_id, null: false
      t.timestamps
    end

    add_index :portfolios, :user_id,      unique: true
    add_index :portfolios, :hstore_data,  using: :gin
  end
end
