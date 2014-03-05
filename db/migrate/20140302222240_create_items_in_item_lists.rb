class CreateItemsInItemLists < ActiveRecord::Migration
  def change
    create_table :items_in_item_lists do |t|
      t.references :item_list
      t.string :item

      t.timestamps
    end
    add_index :items_in_item_lists, :item_list_id
  end
end
