class CreateItemsAndDocuments < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :uri
      t.string :handle
      t.string :primary_text_path
      t.string :annotation_path
      t.references :collection

      t.timestamps
    end

    create_table :documents do |t|
      t.string :file_name
      t.string :file_path
      t.string :type
      t.string :mime_type
      t.references :item
      t.timestamps
    end
  end

end
