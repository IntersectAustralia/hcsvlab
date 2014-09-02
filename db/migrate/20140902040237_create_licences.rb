class CreateLicences < ActiveRecord::Migration
  def change
    create_table :licences do |t|
      t.string :name
      t.text :text
      t.string :type
      t.string :ownerId
      t.string :ownerEmail

      t.timestamps
    end
  end
end
