class AddJsonMetadataToItem < ActiveRecord::Migration
  def change
    add_column :items, :json_metadata, :text
  end
end
