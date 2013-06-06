class CreateItemLists < ActiveRecord::Migration
  def up
    create_table :item_lists do |t|
      t.references :user, :null=>false
      t.string :name, :null=>false
      t.timestamps
    end
  end

  def down
    drop_table :item_lists
  end
end
