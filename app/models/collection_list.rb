class CollectionList < ActiveRecord::Base

  has_many :collections, uniq: true
  belongs_to :licence
  belongs_to :owner, class_name: 'User'

  validates_presence_of :name, message: 'Collection List Name can not be blank'
  validates_length_of :name, maximum: 255, message: "Name is too long (maximum is 255 characters)"
  validates_presence_of :owner_id, message: 'Collection List owner id can not be empty'
  validates_presence_of :owner_email, message: 'Collection List owner email can not be empty'

  validate :same_license_integrity_check

  before_destroy :remove_collection_licences

  def set_privacy(status)
    self.private = status
    self.save!
  end

  # Query of privacy status
  def public?
    !private?
  end

  #
  # Adds collections to a Collection List
  #
  def add_collections(collection_ids)
    self.collection_ids << collection_ids
    self.set_license(self.licence)
    self.save!
  end

  #
  # Removes a collection from its Collection List
  #
  def remove_collection(collection_id)
    if collections.length <= 1
      self.delete
    else
      collection = Collection.find(collection_id)
      collection.collection_list_id = nil
      collection.licence = nil
      collection.save!
    end
  end

  #
  # Adds licence to collection list
  #
  def set_license(licence)
    licence = Licence.find(licence.to_s) unless licence.is_a? Licence

    Rails.logger.debug "Adding licence #{licence.id} to collection list #{self.id}"

    self.collections.update_all(license_id: licence.id)
  end

  private

  #
  # Removes the licence of every Collection contained in this Collection List
  #
  def remove_collection_licences
    self.collections.update_all(license_id: nil)
  end

  #
  # Checks that that licence of this Collection List is the same than the licence of the Collections contained in
  # this Collection List.
  #
  def same_license_integrity_check

    licenses = [license_id] + collections.pluck(:license_id)
    error = licenses.uniq.size == 1
    if error
      errors[:base] << "All Collection in a Collection List must have the same licence"
      collections.where('license_id != ?', license_id.to_i).each do |collection|
        Rails.logger.debug "Collection #{collection.id} has licence #{collection.licence.name}, but the Collection List #{self.id} has licence #{self.collection.name}"
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
  def self.create_public_list(name, new_licence, *collection_names)
    # Check there isn't already a CollectionList with that name.
    if CollectionList.find_by_name(name).present?
      Rails.logger.error("CollectionList.create_public_list: there is already a CollectionList called #{name}")
      return nil
    end

    # Find the Collections with the given collection_names
    warnings = []
    missing = collection_names - Collection.where(short_name: collection_names).pluck(:short_name)
    grouped_in_list = Collection.where(short_name: collection_names).where('license_id is not null')
    warnings += missing.collect{|cn| "cannot find a Collection called #{cn}" }
    warnings += grouped_in_list.collect{|cn| "Collection #{cn.short_name} is already part of CollectionList #{cn.licence.name}" }

    to_add = Collection.where(short_name: collection_names, license_id: nil)

    unless warnings.empty?
      # There were missing collections.
      warnings.each { |w|
        Rails.logger.warning("CollectionList.create_public_list: #{w}")
      }
    end

    if to_add.empty?
      Rails.logger.error("CollectionList.create_public_list: no viable collections in argument list!")
      return nil
    else
      user = to_add.first.owner
    end

    # Do the actual creation and adding
    result = CollectionList.new
    result.name = name
    result.owner_email = user.email
    result.owner_id = user.id.to_s
    result.private = false
    result.save
    result.add_collections(to_add.pluck(:id))
    result.set_license(new_licence) unless new_licence.nil?

    Rails.logger.info("Collection list #{result.name} created with #{result.collection_ids.size} collection(s)")
    Rails.logger.info("Licence #{new_licence.name} assigned to Collection list #{result.name}") unless new_licence.nil?

    # Return the new CollectionList
    return result
  end
  # End of Support for creation of CollectionLists via scripts
  # ---------------------------------------------------------------------------
  #
end