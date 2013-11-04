class FixLicenceAgreementColumnNames < ActiveRecord::Migration
  def change
  	rename_column :user_licence_agreements, :groupName, :group_name
  	rename_column :user_licence_agreements, :licenceId, :licence_id
  end
end
