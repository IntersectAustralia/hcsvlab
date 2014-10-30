class AddIndexedAtToItem < ActiveRecord::Migration
  def change
    add_column :items, :indexed_at, :datetime
  end
end
