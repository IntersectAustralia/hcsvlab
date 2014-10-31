class CreateHandleIndexForItems < ActiveRecord::Migration
  def change
    add_index :items, :handle
  end

end
