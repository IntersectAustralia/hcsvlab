class CollectionList < ActiveRecord::Base

  has_many :collections, uniq: true
  belongs_to :licence
  belongs_to :owner, class_name: 'User'

  validates_presence_of :name, message: 'Collection List Name can not be blank'
  validates_length_of :name, maximum: 255, message: "Name is too long (maximum is 255 characters)"
  validates_presence_of :owner_id, message: 'Collection List owner id can not be empty'

  validate :same_licence_integrity_check

  before_destroy :remove_collection_licences

  attr_accessible :name, :private


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
    self.collection_ids += collection_ids
    self.collections.update_all(licence_id: self.licence_id)
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
  def set_licence(licence)
    licence_id = licence.is_a?(Licence) ? licence.id : licence
    Rails.logger.debug "Adding licence #{licence_id} to collection list #{self.id}"
    self.update_attribute(:licence_id, licence_id)
    self.collections.update_all(licence_id: licence_id)
  end

  private

  #
  # Removes the licence of every Collection contained in this Collection List
  #
  def remove_collection_licences
    self.update_attribute(:licence_id, nil)
    self.collections.update_all(licence_id: nil)
  end

  #
  # Checks that that licence of this Collection List is the same than the licence of the Collections contained in
  # this Collection List.
  #
  def same_licence_integrity_check

    licences = [licence_id] + self.collections.pluck(:licence_id)

    if licences.uniq.size > 1
      errors[:base] << "All Collection in a Collection List must have the same licence"
      collections.where('licence_id != ?', licence_id.to_i).each do |collection|
        Rails.logger.debug "Collection #{collection.id} has licence #{collection.licence.try(:name)}, but the Collection List #{self.id} has licence #{self.licence.try(:name)}"
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
    missing = collection_names - Collection.where(name: collection_names).pluck(:name)
    grouped_in_list = Collection.where(name: collection_names).where('licence_id is not null')
    warnings += missing.collect{|cn| "cannot find a Collection called #{cn}" }
    warnings += grouped_in_list.collect{|cn| "Collection #{cn.name} is already part of CollectionList #{cn.licence.name}" }

    to_add = Collection.where(name: collection_names, licence_id: nil)

    unless warnings.empty?
      # There were missing collections.
      warnings.each { |w|
        Rails.logger.warn("CollectionList.create_public_list: #{w}")
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
    result.owner_id = user.id.to_s
    result.private = false
    result.save
    result.add_collections(to_add.pluck(:id))
    result.set_licence(new_licence) unless new_licence.nil?

    Rails.logger.info("Collection list #{result.name} created with #{result.collection_ids.size} collection(s)")
    Rails.logger.info("Licence #{new_licence.name} assigned to Collection list #{result.name}") unless new_licence.nil?

    # Return the new CollectionList
    return result
  end
  # End of Support for creation of CollectionLists via scripts
  # ---------------------------------------------------------------------------
  #
end