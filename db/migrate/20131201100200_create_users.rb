class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, id: :uuid do |t|
      t.string    :name,                    null: false
      t.string    :email,                   null: false
      t.string    :image_url
      t.string    :password_digest
      t.string    :authentication_token
      t.boolean   :admin,                   null: false, default: false
      t.boolean   :from_oauth,              null: false, default: false
      t.integer   :sign_in_count,           null: false, default: 0
      t.datetime  :last_sign_in_at
      t.datetime  :accepted_terms
      t.datetime  :confirmed_at

      t.hstore    :data

      t.timestamps
    end

    add_index :users, :email,                 unique: true
    add_index :users, :authentication_token,  unique: true
    add_index :users, :data,                  using: :gin
  end
end
