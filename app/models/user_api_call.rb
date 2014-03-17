class UserApiCall < ActiveRecord::Base

  belongs_to :user

  attr_accessible :request_time, :item_list

end