include ActiveFedora::DatastreamCollections

class CollectionList  < ActiveFedora::Base

  has_metadata 'descMetadata', type: Datastream::CollectionListMetadata

  has_many :collections, :property => :is_member_of
  belongs_to :licence, :property => :is_part_of

  delegate :name, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

  def add_collections(collection_ids)
    collection_ids.each do |aCollectionsId|
      self.collections=[] if self.collections.nil?

      self.collections << Collection.find(aCollectionsId.to_s)
    end
    self.save!
  end

  def self.find_by_owner_id(userId)
    return CollectionList.find(ownerId:userId.to_s)
  end

end