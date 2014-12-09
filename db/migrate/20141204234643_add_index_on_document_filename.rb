class AddIndexOnDocumentFilename < ActiveRecord::Migration
  def change
    add_index :documents, :file_name
    add_index :documents, :file_path
    add_index :items, :uri
  end

end
