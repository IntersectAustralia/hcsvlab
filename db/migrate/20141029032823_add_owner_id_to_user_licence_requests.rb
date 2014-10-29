class AddOwnerIdToUserLicenceRequests < ActiveRecord::Migration
  def change
    UserLicenceRequest.delete_all
    add_column :user_licence_requests, :owner_id, :integer
  end
end
