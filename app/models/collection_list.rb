include ActiveFedora::DatastreamCollections

class CollectionList  < ActiveFedora::Base

  has_metadata 'descMetadata', type: Datastream::CollectionListMetadata

  has_many :collections, :property => :is_member_of
  belongs_to :licence, :property => :is_part_of

  delegate :name, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'


  #
  # Adds licence to collection list
  #
  def add_licence(licence_id)
  	Rails.logger.debug "Adding licence #{licence_id} to collection list #{self.id}"
  	self.licence = Licence.find(licence_id)
  	self.save
  end
end