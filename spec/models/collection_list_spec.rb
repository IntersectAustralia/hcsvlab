require 'spec_helper'

describe CollectionList do
  
  describe "Collection List Descriptive Metadata" do

    it "should persist metadata about a Collection List" do
      c = CollectionList.new
      c.name = "coll_list"

      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      c.ownerId = u.id.to_s
      c.ownerEmail = u.email

      c.save
      pid = c.pid

      coll = CollectionList.find(pid)
      coll.name[0].should eq "coll_list"
      coll.ownerId[0].to_i.should eq u.id
      coll.ownerEmail[0].should eq "test@intersect.org.au"
    end

  end

  describe "Collection List Licence" do

    it "should persist licence information for a Collection List" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      c = FactoryGirl.create(:collection_list, :ownerId => u.id.to_s, :ownerEmail => u.email)
      l = FactoryGirl.create(:licence, :ownerId => u.id.to_s, :ownerEmail => u.email)

      c.licence = l
      c.save
      pid = c.pid

      coll = CollectionList.find(pid)
      coll.licence.name[0].should eq "Creative Commons"
      coll.licence.text[0].should eq "Creative Commons Licence Terms"
      coll.licence.type[0].should eq Licence::LICENCE_TYPE_PUBLIC
      coll.licence.ownerEmail[0].should eq "test@intersect.org.au"
    end

  end

end