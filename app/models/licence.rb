class Licence < ActiveRecord::Base

  LICENCE_TYPE_PRIVATE = "PRIVATE"
  LICENCE_TYPE_PUBLIC = "PUBLIC"

  attr_accessible :name, :owner_id, :text, :type
  belongs_to :owner, class_name: 'User'

  # Validations
  validates_presence_of :name, message: 'Licence Name can not be blank'
  validates_length_of :name, maximum: 255, message:'Name is too long (maximum is 255 characters)'
  validates_uniqueness_of :name, scope: :owner_id
  validates_presence_of :text, message: 'Licence Text can not be blank'
  validates_presence_of :type, message: 'Type can not be blank'

  validates :type, inclusion: { in: %w(PRIVATE PUBLIC), message: "%{value} is not a valid Type" }

end
