class UserLicenceRequest < ActiveRecord::Base

  belongs_to :user
  attr_accessible :request_type, :request_id, :owner_email

  validates_presence_of :request_type, :request_id, :owner_email

  def user_email
    @user = self.user
    @user.email
  end

  def request
  	return Collection.find(self.request_id) if self.request_type == "collection"
    return CollectionList.find(self.request_id) if self.request_type == "collection_list"
  end

end