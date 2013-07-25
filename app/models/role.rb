class Role < ActiveRecord::Base

  SUPERUSER_ROLE = 'hcsvlab-admin'
  RESEARCHER_ROLE = 'researcher'
  DATA_OWNER_ROLE = 'data owner'

  attr_accessible :name

  has_many :users

  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}

  scope :by_name, order('name')
  scope :superuser_roles, where(:name => SUPERUSER_ROLE)
  scope :researcher_roles, where(:name => RESEARCHER_ROLE)
  scope :data_owner_roles, where(:name => DATA_OWNER_ROLE)

end
