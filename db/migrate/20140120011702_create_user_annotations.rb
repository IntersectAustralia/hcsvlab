class CreateUserAnnotations < ActiveRecord::Migration
  def change
    create_table :user_annotations do |t|
      t.references :user
      t.string :original_filename
      t.string :file_type
      t.integer :size_in_bytes
      t.string :item_identifier
      t.boolean :shareable
      t.string :file_location
      t.string :annotationCollectionId

      t.timestamps
    end
    add_index :user_annotations, :user_id
  end
end
