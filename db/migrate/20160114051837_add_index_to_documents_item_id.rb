class AddIndexToDocumentsItemId < ActiveRecord::Migration
  def change
    add_index :documents, :item_id, :name => "index_documents_item_id"
  end
end
