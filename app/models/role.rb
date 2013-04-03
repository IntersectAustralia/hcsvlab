class Role < ActiveRecord::Base

  attr_accessible :name

  has_many :users

  validates :name, :presence => true, :uniqueness => {:case_sensitive => false}

  scope :by_name, order('name')
  scope :superuser_roles, where(:name => 'hcsvlab-admin')

end
