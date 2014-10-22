class ChangeTypeToPrivateInLicences < ActiveRecord::Migration
  def up
    remove_column :licences, :type
    add_column :licences, :private, :boolean
  end

  def down
    remove_column :licences, :private
    add_column :licences, :type, :string
  end
end
