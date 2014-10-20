class CreateCollectionAndList < ActiveRecord::Migration
  def change
    create_table :collection_lists do |t|
      t.string :name
      t.boolean :private
      t.references :license
      t.references :owner

      t.timestamps
    end

    create_table :collections do |t|
      t.string :uri
      t.text :text
      t.string :name
      t.text :rdf_file_path
      t.boolean :private
      t.references :owner
      t.references :collection_list
      t.references :license
      t.timestamps
    end

    remove_column :user_licence_requests, :owner_email
  end
end
