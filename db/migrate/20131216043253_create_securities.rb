class CreateSecurities < ActiveRecord::Migration
  def change
    create_table :securities, id: :uuid do |t|
      t.string  :ticker,            null: false
      t.string  :asset_class,       null: false
      t.string  :asset_type,        null: false

      t.decimal :mean_return,       null: false
      t.decimal :std_dev,           null: false
      t.decimal :implied_return,    null: false
      t.decimal :returns,           null: false, array: true, default: []

      t.timestamps
    end

    add_index :securities, :ticker,      unique: true
    add_index :securities, :asset_class
  end
end
