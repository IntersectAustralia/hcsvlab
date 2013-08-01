class License < ActiveFedora::Base

	has_metadata 'descMetadata', type: Datastream::LicenseMetadata


	delegate :name, to: 'descMetadata'
	delegate :text, to: 'descMetadata'

end