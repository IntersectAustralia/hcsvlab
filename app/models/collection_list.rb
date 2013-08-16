include ActiveFedora::DatastreamCollections

class CollectionList < ActiveFedora::Base
  has_metadata 'descMetadata', type: Datastream::CollectionListMetadata

  has_many :collections, :property => :is_part_of
  belongs_to :licence, :property => :has_licence

  delegate :name, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'

  validates_presence_of :flat_name, message: 'Collection List Name can not be blank'
  validates_presence_of :flat_ownerId, message: 'Collection List owner id can not be empty'
  validates_presence_of :flat_ownerEmail, message: 'Collection List owner email can not be empty'

  validate :sameLicenceIntegrityCheck

  # ActiveFedora returns the value as an array, we need the first value
  def flat_name
    self[:name].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_ownerId
    self[:ownerId].first
  end

  # ActiveFedora returns the value as an array, we need the first value
  def flat_ownerEmail
    self[:ownerEmail].first
  end

  #
  # Gets the Collection Lists for the given user
  #
  def self.find_by_owner_id(userId)
    return CollectionList.find(ownerId:userId.to_s)
  end

  #
  # Adds collections to a Collection List
  #
  def add_collections(collection_ids)
    collection_ids.each do |aCollectionsId|
      self.collections=[] if self.collections.nil?
      begin
        aCollection = Collection.find(aCollectionsId.to_s)
        # We are only adding Collections that are not assigned to any other Collection List.
        if (aCollection.collectionList.nil?)
          self.collections << aCollection
          aCollection.setCollectionList(self)

          # for some reason, sometime the licence object is not retrieved and I need to fetch it
          aLicence = (self.licence.nil?)? nil : Licence.find(self.licence.id)
          aCollection.setLicence(aLicence)
        end
      rescue ActiveFedora::ObjectNotFoundError => e
        Rails.logger.debug "Error finding collection #{aCollectionsId.to_s}"
        # If the Collection does not exist, then do nothing.
      end
    end
    self.save!
  end

  #
  # Removes a collection from its Collection List
  #
  def remove_collection(collectionId)
    if (collections.length <= 1)
      self.delete
    else
      collection = Collection.find(collectionId)
      collection.collectionList = nil
      collection.licence = nil
      collection.save!
    end
  end

  #
  # Adds licence to collection list
  #
  def setLicence(licence_id)
  	Rails.logger.debug "Adding licence #{licence_id} to collection list #{self.id}"
  	aLicence = Licence.find(licence_id)

    self.collections.each do |aCollection|
      aCollection.licence = aLicence
      aCollection.save!
    end

    self.licence = aLicence
  	self.save!
  end

  def delete
    removeLicenceFromCollections
    super
  end

  private

  #
  # Removes the licence of every Collection contained in this Collection List
  #
  def removeLicenceFromCollections
    self.collections.each do |aCollection|
      aCollection.collectionList = nil
      aCollection.licence = nil
      aCollection.save!
    end
  end

  #
  # Checks that that licence of this Collection List is the same than the licence of the Collections contained in
  # this Collection List.
  #
  def sameLicenceIntegrityCheck
    if (!collections.nil?)
      error = false
      collections.each do |aCollection|
        # if the collection list licence is null, then the licence for the collection must be null
        if (licence.nil?)
          error = error || !aCollection.licence.nil?
        else
          error = error || aCollection.licence.nil?
          if (!aCollection.licence.nil?)
            error = error || !licence.id.eql?(aCollection.licence.id)
          end
        end
        if (error)
          Rails.logger.debug "Collection #{aCollection.id} has licence #{aCollection.licence.inspect}, but the Collection List #{self.id} has licence #{self.licence.inspect}"
        end
      end
      if (error)
        errors[:base] << "All Collection in a Collection List must have the same licence"
      end
    end
  end
end