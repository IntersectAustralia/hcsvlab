class AddUserSession < ActiveRecord::Migration
  def change
  	create_table :user_sessions do |t|
      t.datetime :sign_in_time
      t.datetime :sign_out_time
      t.references :user

      t.timestamps
    end
    add_index :user_sessions, :user_id
  end
end
