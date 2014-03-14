class AddUserSearches < ActiveRecord::Migration
  def change
  	create_table :user_searches do |t|
      t.datetime :search_time
      t.string :search_type
      t.references :user

      t.timestamps
    end
    add_index :user_searches, :user_id
  end
end