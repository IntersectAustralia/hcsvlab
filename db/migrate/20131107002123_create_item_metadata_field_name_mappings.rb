class CreateItemMetadataFieldNameMappings < ActiveRecord::Migration
  def change
    create_table :item_metadata_field_name_mappings do |t|
      t.string :solr_name
      t.string :rdf_name
      t.string :user_friendly_name
      t.string :display_name

      t.timestamps
    end
    add_index :item_metadata_field_name_mappings, :solr_name, :unique => true
  end
end
