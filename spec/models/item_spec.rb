require 'spec_helper'

describe Item do

  describe "Item-Document Relationships" do

  	it "should persist relationship between Item and Document" do
  		# Create item
  		item = Item.new
  		item.save
  		item_pid = item.pid

  		# Create document and add it to item
  		doc = Document.new
  		doc.item = item
  		doc.save
  		doc_pid = doc.pid

  		# Fetch item and make sure it has a document
  		item2 = Item.find(item_pid)
  		item2.documents.count.should eq 1
  		item2.documents[0].pid.should eq doc_pid
  	end

  end

  describe "Item-Collection Relationships" do

    it "should persist relationship between Item and Collection" do
      # Create a collection and add the item to it
      col = Collection.new
      col.save
      col_pid = col.pid

      # Create item
      item = Item.new
      item.collection = col
      item.save
      item_pid = item.pid

      col1 = Collection.find(col_pid)
      col1.items.count.should eq 1
      col1.items[0].pid.should eq item_pid

    end
  end
end