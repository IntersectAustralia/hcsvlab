class CreateCollectionAndList < ActiveRecord::Migration
  def change
    create_table :collection_list do |t|
      t.string :name
      t.boolean :private
      t.references :license
      t.references :owner

      t.timestamps
    end

    create_table :collection do |t|
      t.string :uri
      t.text :text
      t.string :name
      t.boolean :private
      t.references :owner
      t.references :collection_list
      t.references :license
      t.timestamps
    end

  end
end
