class UserLicenceRequest < ActiveRecord::Base

  belongs_to :user
  attr_accessible :groupName, :timestamp, :owner_email

  validates_presence_of :timestamp
  validates_presence_of :groupName

  def user_email
    @user = self.user
    @user.email
  end  

end