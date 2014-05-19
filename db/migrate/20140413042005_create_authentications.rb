class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications, id: :uuid do |t|
      t.string    :uid,           null: false
      t.string    :provider,      null: false
      t.string    :username
      t.text      :oauth_token  # Amazon incredibly long tokens
      t.text      :oauth_secret
      t.datetime  :oauth_expires

      t.uuid      :user_id,       null: false
      t.timestamps
    end

    add_index :authentications, :user_id
    add_index :authentications, [:provider, :uid]
  end
end
