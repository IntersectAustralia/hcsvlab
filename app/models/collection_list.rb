include ActiveFedora::DatastreamCollections

class CollectionList  < ActiveFedora::Base

  has_metadata 'descMetadata', type: Datastream::CollectionListMetadata

  has_many :collections, :property => :is_member_of
  belongs_to :licence, :property => :is_part_of

  delegate :name, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

end