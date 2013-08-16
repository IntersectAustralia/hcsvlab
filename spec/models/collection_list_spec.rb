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
      c.ownerId = u.id.to_s
      c.ownerEmail = u.email

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
      c = FactoryGirl.create(:collection_list, :ownerId => u.id.to_s, :ownerEmail => u.email)
      l = FactoryGirl.create(:licence, :ownerId => u.id.to_s, :ownerEmail => u.email)

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
      cl = FactoryGirl.create(:collection_list, :ownerId => u.id.to_s, :ownerEmail => u.email)
      c = FactoryGirl.create(:collection, :private_data_owner => u.id.to_s)
      l1 = FactoryGirl.create(:licence, :ownerId => u.id.to_s, :ownerEmail => u.email)
      l2 = FactoryGirl.create(:licence, :ownerId => u.id.to_s, :ownerEmail => u.email)

      # Set licence L1 to the Collection
      c.setLicence(l1)
      # Set licence L2 to the Collection List
      cl.setLicence(l2.id)

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
      cl = FactoryGirl.create(:collection_list, :ownerId => u.id.to_s, :ownerEmail => u.email)
      c = FactoryGirl.create(:collection, :private_data_owner => u.id.to_s)
      l1 = FactoryGirl.create(:licence, :ownerId => u.id.to_s, :ownerEmail => u.email)

      # Set licence L1 to the Collection List
      cl.setLicence(l1.id)

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