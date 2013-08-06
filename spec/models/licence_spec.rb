require 'spec_helper'

describe Licence do
  
  describe "Licence Descriptive Metadata" do

    it "should persist metadata about a Licence" do
      l = Licence.new
      l.name = "CC Licence"
      l.text = "Various text outlining terms of the licence"
      l.type = Licence::LICENCE_TYPE_PUBLIC

      u = FactoryGirl.create(:user, :status => 'A', :email => "test@intersect.org.au")
      l.ownerId = u.id.to_s
      l.ownerEmail = u.email

      l.save
      pid = l.pid

      lic = Licence.find(pid)
      lic.name[0].should eq "CC Licence"
      lic.text[0].should eq "Various text outlining terms of the licence"
      lic.type[0].should eq Licence::LICENCE_TYPE_PUBLIC
      lic.ownerId[0].to_i.should eq u.id
      lic.ownerEmail[0].should eq "test@intersect.org.au"
    end

  end

end