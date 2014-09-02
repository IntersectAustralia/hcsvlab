class Licence < ActiveRecord::Base

  LICENCE_TYPE_PRIVATE = "PRIVATE"
  LICENCE_TYPE_PUBLIC = "PUBLIC"

  attr_accessible :name, :ownerEmail, :ownerId, :text, :type

  # Validations
  validates_presence_of :name, message: 'Licence Name can not be blank'
  validates_length_of :name, maximum: 255, message:'Name is too long (maximum is 255 characters)'
  validates_presence_of :text, message: 'Licence Text can not be blank'
  validates_presence_of :type, message: 'Type can not be blank'

  validates :type, inclusion: { in: %w(PRIVATE PUBLIC), message: "%{value} is not a valid Type" }
  validate :uniqueLicenceName

  private

  #
  # Validates that the licence name does not exist either in the Public Licences or in the user licences
  #
  def uniqueLicenceName
    licencesNames = Licence.find_by_type(LICENCE_TYPE_PUBLIC).map {|aLicence| aLicence.name}
    if (!self.ownerId.nil? and !self.ownerId.empty?)
      licencesNames.concat Licence.find_by_ownerId(self.ownerId).map {|aLicence| aLicence.name}
    end

    if (licencesNames.include?(self.name))
      errors[:base] << "Licence name '#{self.name}' already exists"
    end
  end
end
