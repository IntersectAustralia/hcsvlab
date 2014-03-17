class AddUserApiCalls < ActiveRecord::Migration
  def change
  	create_table :user_api_calls do |t|
      t.datetime :request_time
      t.boolean :item_list
      t.references :user

      t.timestamps
    end
    add_index :user_api_calls, :user_id
  end
end
