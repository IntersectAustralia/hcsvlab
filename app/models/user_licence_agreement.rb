class UserLicenceAgreement < ActiveRecord::Base
  DISCOVER_ACCESS_TYPE = "discover"
  READ_ACCESS_TYPE = "read"
  EDIT_ACCESS_TYPE = "edit"

  belongs_to :user
  attr_accessible :groupName, :licenceId
end
