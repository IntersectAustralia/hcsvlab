class Licence < ActiveFedora::Base

  LICENSE_TYPE_PRIVATE = "PRIVATE"
  LICENSE_TYPE_PUBLIC = "PUBLIC"

	has_metadata 'descMetadata', type: Datastream::LicenseMetadata

	delegate :name, to: 'descMetadata'
	delegate :text, to: 'descMetadata'
  delegate :type, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

end