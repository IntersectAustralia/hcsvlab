class UserSearch < ActiveRecord::Base

  belongs_to :user

  attr_accessible :search_time, :search_type

end