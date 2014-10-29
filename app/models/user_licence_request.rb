class UserLicenceRequest < ActiveRecord::Base

  belongs_to :user
  # TODO try polymorphic association

  attr_accessible :request_type, :request_id, :approved, :owner_id

  validates_presence_of :request_type, :request_id

  def user_email
    @user = self.user
    @user.email
  end

  def request
  	return Collection.find(self.request_id) if self.request_type == "collection"
    return CollectionList.find(self.request_id) if self.request_type == "collection_list"
  end

  def approve
    self.approved = true
    self.save!
  end

end