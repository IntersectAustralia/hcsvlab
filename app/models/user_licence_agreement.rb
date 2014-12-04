class UserLicenceAgreement < ActiveRecord::Base
  DISCOVER_ACCESS_TYPE = "discover"
  READ_ACCESS_TYPE = "read"
  EDIT_ACCESS_TYPE = "edit"

  belongs_to :user
  attr_accessible :name, :access_type, :collection_type, :licence_id

  def self.type_or_higher(access_type)
    case access_type
      when DISCOVER_ACCESS_TYPE
        return [DISCOVER_ACCESS_TYPE, READ_ACCESS_TYPE, EDIT_ACCESS_TYPE]
      when READ_ACCESS_TYPE
        return [READ_ACCESS_TYPE, EDIT_ACCESS_TYPE]
      when EDIT_ACCESS_TYPE
        return [EDIT_ACCESS_TYPE]
    end
  end

end
