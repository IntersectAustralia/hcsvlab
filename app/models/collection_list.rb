include ActiveFedora::DatastreamCollections

class CollectionList < HcsvlabActiveFedora
  has_metadata 'descMetadata', type: Datastream::CollectionListMetadata

  has_many :collections, :property => :is_part_of
  belongs_to :licence, :property => :has_licence

  delegate :name, to: 'descMetadata'
  delegate :ownerId, to: 'descMetadata'
  delegate :ownerEmail, to: 'descMetadata'
  delegate :privacy_status, to: 'descMetadata'

  validates_presence_of :flat_name, message: 'Collection List Name can not be blank'
  validates_length_of :flat_name, maximum: 255, message:"Name is too long (maximum is 255 characters)"
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
  # Find a collection using its short_name
  #
  def self.find_by_name(name)
    return CollectionList.where(name: name).all
  end

  def setPrivacy(status)
    self.privacy_status = status
    self.save!
  end

  # Query of privacy status
  def private?
    self[:privacy_status].first == "true"
  end

  # Query of privacy status
  def public?
    self[:privacy_status].first == "false"
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
  def setLicence(licence)
    licence = Licence.find(licence.to_s) unless licence.is_a? Licence

    Rails.logger.debug "Adding licence #{licence.id} to collection list #{self.id}"

    self.collections.each do |aCollection|
      aCollection.licence = licence
      aCollection.save!
    end

    self.licence = licence
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

  #
  # ===========================================================================
  # Support for creation of CollectionLists via scripts
  # ===========================================================================
  #

  #
  # Create a public collection list with the given name and add the collections
  # with the given short names to it. Assign the new CollectionList to the
  # owner of the first collection. Return the new CollectionList if one was
  # created, otherwise return nil. Note that if there is already a
  # CollectionList with the given name then _no Collections will be added to
  # it_. Be tolerant of collections which are named but do not exist - just
  # skip them (with a warning). Once the CollectionList has been created,
  # assign the given licence to it (allow a nil licence).
  #
  def self.create_public_list(name, licence, *collection_names)
    # Check there isn't already a CollectionList with that name.
    cls = CollectionList.find_by_name(name)
    unless cls.empty?
      Rails.logger.error("CollectionList.create_public_list: there is already a CollectionList called #{name}")
      return nil
    end

    # Find the Collections with the given collection_names
    user = nil
    found = []
    warnings = []
    collection_names.each { |cn|
      array = Collection.find_by_short_name(cn)
      if array.empty?
        # Couldn't find such a collection
        warnings << "cannot find a Collection called #{cn}"
      elsif !array[0].collectionList.nil?
        # Collection is already in a list
        warnings << "Collection #{cn} is already part of CollectionList #{array[0].collectionList.name}"
      else
        # got it!
        found << array[0].id
        user = array[0].data_owner if user.nil?
      end
    }

    unless warnings.empty?
      # There were missing collections.
      warnings.each { |w|
        Rails.logger.warning("CollectionList.create_public_list: #{w}")
      }
    end

    if found.empty?
      Rails.logger.error("CollectionList.create_public_list: no viable collections in argument list!")
      return nil
    end

    # Do the actual creation and adding
    result = CollectionList.new
    result.name           = name
    result.ownerEmail     = user.email
    result.ownerId        = user.id.to_s
    result.privacy_status = 'false'
    result.save
    result.add_collections(found)
    result.setLicence(licence) unless licence.nil?

    Rails.logger.info("Collection list #{result.name} created with #{result.collection_ids.size} collection(s)")
    Rails.logger.info("Licence #{licence.name} assigned to Collection list #{result.name}") unless licence.nil?

    # Return the new CollectionList
    return result
  end
  # End of Support for creation of CollectionLists via scripts
  # ---------------------------------------------------------------------------
  #
end