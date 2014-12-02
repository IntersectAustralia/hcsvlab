class CreateDocumentAudits < ActiveRecord::Migration
  def change
    create_table :document_audits do |t|
      t.integer :document_id
      t.integer :user_id

      t.timestamps
    end
  end
end
