class CreateLicences < ActiveRecord::Migration
  def change
    create_table :licences do |t|
      t.string :name
      t.text :text
      t.string :type
      t.references :owner
      t.timestamps
    end
  end
end
