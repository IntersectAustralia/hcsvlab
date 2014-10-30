class Licence < ActiveRecord::Base

  attr_accessible :name, :owner_id, :text, :private
  belongs_to :owner, class_name: 'User'

  # Validations
  validates_presence_of :name, message: 'Licence Name can not be blank'
  validates_length_of :name, maximum: 255, message:'Name is too long (maximum is 255 characters)'
  validates_uniqueness_of :name, scope: :owner_id, message: "Licence name '%{value}' already exists"
  validates_presence_of :text, message: 'Licence Text can not be blank'

end
