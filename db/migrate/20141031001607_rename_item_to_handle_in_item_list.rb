class RenameItemToHandleInItemList < ActiveRecord::Migration
  def change
    rename_column :items_in_item_lists, :item, :handle
  end
end
