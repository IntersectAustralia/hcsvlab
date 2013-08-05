class Licence < ActiveFedora::Base

  LICENCE_TYPE_PRIVATE = "PRIVATE"
  LICENCE_TYPE_PUBLIC = "PUBLIC"

  has_metadata 'descMetadata', type: Datastream::LicenceMetadata

  delegate :name, to: 'descMetadata'
  delegate :text, to: 'descMetadata'
  delegate :type, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

end