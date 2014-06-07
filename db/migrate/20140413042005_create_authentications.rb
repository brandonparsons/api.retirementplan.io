class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications, id: :uuid do |t|
      t.string    :uid,           null: false
      t.string    :provider,      null: false
      t.text      :oauth_token    # Some services (e.g. Amazon) incredibly long tokens
      t.datetime  :oauth_expires

      t.uuid      :user_id,       null: false
      t.timestamps
    end

    add_index :authentications, :user_id
    add_index :authentications, [:provider, :uid]
  end
end
