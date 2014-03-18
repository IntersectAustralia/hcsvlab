class AddSharedToItemLists < ActiveRecord::Migration
  def change
    add_column :item_lists, :shared, :boolean
  end
end
