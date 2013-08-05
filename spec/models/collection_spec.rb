require 'spec_helper'

describe Collection do
  
  describe "Collection Descriptive Metadata" do

    it "should persist metadata about a Collection" do
      coll = Collection.new
      coll.uri = 'http://ns.ausnc.org.au/colly'
      coll.short_name = 'colly'
      coll.save
      pid = coll.pid

      coll2 = Collection.find(pid)
      coll2.uri[0].should eq 'http://ns.ausnc.org.au/colly'
      coll2.short_name[0].should eq 'colly'
    end

  end

end