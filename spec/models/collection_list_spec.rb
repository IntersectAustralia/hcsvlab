require 'spec_helper'

describe CollectionList do
  before(:each) do
    CollectionList.delete_all
    Collection.delete_all
    Licence.delete_all
  end
  after(:each) do
    CollectionList.delete_all
    Collection.delete_all
    Licence.delete_all
  end

  describe "Collection List Descriptive Metadata" do

    it "should persist metadata about a Collection List" do
      c = CollectionList.new
      c.name = "coll_list"

      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      c.owner_id = u.id.to_s

      c.save
      id = c.id

      coll = CollectionList.find(id)
      coll.name.should eq "coll_list"
      coll.owner.should eq u
    end

  end

  describe "Collection List Licence" do
    it "should persist licence information for a Collection List" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      c = FactoryGirl.create(:collection_list, :owner_id => u.id.to_s)
      l = FactoryGirl.create(:licence, :owner_id => u.id.to_s)

      c.licence = l
      c.save
      id = c.id

      coll = CollectionList.find(id)
      coll.licence.name.should match /Creative Commons [0-9]+/
      coll.licence.text.should eq "Creative Commons Licence Terms"
      coll.licence.private.should eq false
      coll.licence.owner.should eq u
    end

    it "should keep integrity between the Collection's licence" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      cl = FactoryGirl.create(:collection_list, :owner_id => u.id)
      c = FactoryGirl.create(:collection, :owner_id => u.id)
      l1 = FactoryGirl.create(:licence, :owner_id => u.id)
      l2 = FactoryGirl.create(:licence, :owner_id => u.id)

      # Set licence L1 to the Collection
      c.set_licence(l1)
      # Set licence L2 to the Collection List
      cl.set_licence(l2.id)

      # Now lets assign the Collection to the Collection List
      cl.add_collections([c.id])

      # After this, the Collection List should have l2 assigned and the same licence should assigned to the Collection
      cl_bis = CollectionList.find(cl.id)
      cl_bis.licence.id.should eq l2.id

      c_bis = Collection.find(c.id)
      c_bis.licence.id.should eq l2.id
    end

    it "should remove Collection's licence when the Collection is removed from the Collection List" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      cl = FactoryGirl.create(:collection_list, :owner_id => u.id)
      c = FactoryGirl.create(:collection, :owner_id => u.id)
      l1 = FactoryGirl.create(:licence, :owner_id => u.id)

      # Set licence L1 to the Collection List
      cl.set_licence(l1.id)

      # Now lets assign the Collection to the Collection List
      cl.add_collections([c.id])

      # After this, the Collection List should have l2 assigned and the same licence should assigned to the Collection
      c_bis = Collection.find(c.id)
      c_bis.licence.id.should eq l1.id

      # Now I will delete the Collection List
      cl.destroy

      # the collection should no have any licence assigned
      c_bis = Collection.find(c.id)
      c_bis.licence.should be nil
    end

  end

end