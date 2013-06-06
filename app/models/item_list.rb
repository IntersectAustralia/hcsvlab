class ItemList < ActiveRecord::Base

  belongs_to :user

  attr_accessible :name, :id

  validates :name, presence: true
end