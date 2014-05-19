class CreateEtfs < ActiveRecord::Migration
  def change
    create_table :etfs, id: :uuid do |t|
      t.string  :ticker,            null: false
      t.text    :description,       null: false

      t.uuid    :security_id,       null: false
      t.timestamps
    end

    add_index :etfs, :security_id
    add_index :etfs, :ticker,       unique: true
  end
end
