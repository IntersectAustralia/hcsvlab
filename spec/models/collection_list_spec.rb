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
      c.owner_email = u.email

      c.save
      pid = c.pid

      coll = CollectionList.find(pid)
      coll.flat_name.should eq "coll_list"
      coll.flat_ownerId.to_i.should eq u.id
      coll.flat_ownerEmail.should eq "test@intersect.org.au"
    end

  end

  describe "Collection List Licence" do
    it "should persist licence information for a Collection List" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      c = FactoryGirl.create(:collection_list, :owner_id => u.id.to_s)
      l = FactoryGirl.create(:licence, :owner_id => u.id.to_s)

      c.licence = l
      c.save
      pid = c.pid

      coll = CollectionList.find(pid)
      coll.licence.flat_name.should match /Creative Commons [0-9]+/
      coll.licence.flat_text.should eq "Creative Commons Licence Terms"
      coll.licence.flat_type.should eq Licence::LICENCE_TYPE_PUBLIC
      coll.licence.flat_ownerEmail.should eq "test@intersect.org.au"
    end

    it "should keep integrity between the Collection's licence" do
      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      cl = FactoryGirl.create(:collection_list, :owner_id => u.id.to_s)
      c = FactoryGirl.create(:collection, :private_data_owner => u.id.to_s)
      l1 = FactoryGirl.create(:licence, :owner_id => u.id.to_s)
      l2 = FactoryGirl.create(:licence, :owner_id => u.id.to_s)

      # Set licence L1 to the Collection
      c.set_license(l1)
      # Set licence L2 to the Collection List
      cl.set_license(l2.id)

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
      cl = FactoryGirl.create(:collection_list, :owner_id => u.id.to_s)
      c = FactoryGirl.create(:collection, :private_data_owner => u.id.to_s)
      l1 = FactoryGirl.create(:licence, :owner_id => u.id.to_s)

      # Set licence L1 to the Collection List
      cl.set_license(l1.id)

      # Now lets assign the Collection to the Collection List
      cl.add_collections([c.id])

      # After this, the Collection List should have l2 assigned and the same licence should assigned to the Collection
      c_bis = Collection.find(c.id)
      c_bis.licence.id.should eq l1.id

      # Now I will delete the Collection List
      cl.delete

      # the collection should no have any licence assigned
      c_bis = Collection.find(c.id)
      c_bis.licence.should be nil
    end

  end

end