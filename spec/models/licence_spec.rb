require 'spec_helper'

describe Licence do
  before(:each) do
    Licence.delete_all
  end
  after(:each) do
    Licence.delete_all
  end

  describe "Licence Descriptive Metadata" do

    it "should persist metadata about a Licence" do
      rnd = Random.new.rand(1..10000).to_s
      l = Licence.new
      l.name = "CC Licence " + rnd
      l.text = "Various text outlining terms of the licence"
      l.private = false

      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      l.owner = u

      l.save
      pid = l.pid

      lic = Licence.find(pid)
      lic.flat_name.should eq "CC Licence " + rnd
      lic.flat_text.should eq "Various text outlining terms of the licence"
      lic.private.should eq false
      lic.flat_ownerId.to_i.should eq u.id
      lic.flat_ownerEmail.should eq "test@intersect.org.au"
    end

  end

end