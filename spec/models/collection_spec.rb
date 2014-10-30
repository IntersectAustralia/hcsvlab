require 'spec_helper'

describe Collection do
  before(:each) do
    Collection.delete_all
  end
  after(:each) do
    Collection.delete_all
  end

  describe "Collection Descriptive Metadata" do

    it "should persist metadata about a Collection" do
      coll = Collection.new
      coll.uri = 'http://ns.ausnc.org.au/colly'
      coll.name = 'colly'
      coll.save
      id = coll.id

      coll2 = Collection.find(id)
      coll2.uri.should eq 'http://ns.ausnc.org.au/colly'
      coll2.name.should eq 'colly'
    end

  end

end