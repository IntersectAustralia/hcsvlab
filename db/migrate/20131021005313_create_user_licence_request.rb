class CreateUserLicenceRequest < ActiveRecord::Migration
  def change
  	create_table :user_licence_requests do |t|
      t.string :request_id
      t.string :request_type
      t.string :owner_email
      t.boolean :approved
      t.references :user

      t.timestamps
    end
    add_index :user_licence_requests, :user_id
  end
end
