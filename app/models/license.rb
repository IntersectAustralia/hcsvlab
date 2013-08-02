class License < ActiveFedora::Base

  module LicenceType
    :PRIVATE
    :PUBLIC
  end

	has_metadata 'descMetadata', type: Datastream::LicenseMetadata


	delegate :name, to: 'descMetadata'
	delegate :text, to: 'descMetadata'
  delegate :type, to: 'descMetadata'
  delegate :owner, to: 'descMetadata'

end