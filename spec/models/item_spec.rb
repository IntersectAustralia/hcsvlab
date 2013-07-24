require 'spec_helper'

describe Item do
  
  describe "Item Descriptive Metadata" do

    it "should persist metadata about an Item" do
      item = Item.new
      item.collection = 'cooee'
      item.collection_id = '4-425'
      item.save
      pid = item.pid

      item2 = Item.find(pid)
      item2.collection[0].should eq 'cooee'
      item2.collection_id[0].should eq '4-425'
    end

  end

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

end