class CreateUserLicenceAgreements < ActiveRecord::Migration
  def change
    create_table :user_licence_agreements do |t|
      t.string :groupName
      t.string :licenceId
      t.references :user

      t.timestamps
    end
    add_index :user_licence_agreements, :user_id
  end
end
