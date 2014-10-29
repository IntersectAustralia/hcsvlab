class RenameLicenseToLicence < ActiveRecord::Migration
  def change
    rename_column :collection_lists, :license_id, :licence_id
    rename_column :collections, :license_id, :licence_id
  end
end
