class Licence < ActiveFedora::Base

  LICENCE_TYPE_PRIVATE = "PRIVATE"
  LICENCE_TYPE_PUBLIC = "PUBLIC"

  has_metadata 'descMetadata', type: Datastream::LicenceMetadata

  delegate :name, to: 'descMetadata'
  delegate :text, to: 'descMetadata'
  delegate :type, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

  validates_presence_of :flat_name, message: 'Licence Name can not be blank'
  validates_presence_of :flat_text, message: 'Licence Text can not be blank'
  validates_presence_of :flat_type, message: 'Type can not be blank'

  validates :flat_type, inclusion: { in: %w(PRIVATE PUBLIC), message: "%{value} is not a valid Type" }
  validate :uniqueLicenceName


  # ActiveFedora returns the value as an array, we need the first value
  def flat_name
    self[:name].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_text
    self[:text].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_type
    self[:type].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_ownerId
    self[:ownerId].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_ownerEmail
    self[:ownerEmail].first
  end

  private

  #
  # Validates that the licence name does not exist either in the Public Licences or in the user licences
  #
  def uniqueLicenceName
    licencesNames = Licence.find(type:LICENCE_TYPE_PUBLIC).map {|aLicence| aLicence.flat_name}
    if (!self.flat_ownerId.nil? and !self.flat_ownerId.empty?)
      puts "Owner is not null: " + self.flat_ownerId.to_s
      licencesNames << Licence.find(ownerId: self.ownerId).map {|aLicence| aLicence.flat_name}
    end
    if (licencesNames.include?(self.flat_name))
      errors[:base] << "This licence name already exists"
    end
  end
end