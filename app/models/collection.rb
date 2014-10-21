require "#{Rails.root}/lib/solr/solr_helper.rb"

class Collection < ActiveRecord::Base
  include SolrHelper

  has_many :items
  belongs_to :owner, class_name: 'User'
  belongs_to :collection_list
  belongs_to :licence

 # TODO Refactor
  #
  # Set the data owner
  #
  def set_data_owner_and_save(user)
    case user
      when String
        self.private_data_owner = user
      when User
        self.private_data_owner = user.email
      else
        self.private_data_owner = user.to_s
    end

    email = private_data_owner.first
    self.set_discover_users([email], self.discover_users)
    self.set_read_users([email], self.read_users)
    self.set_edit_users([email], self.edit_users)
    self.save

    self.items.each do |aItem|
      aItem.set_discover_users([email], aItem.discover_users)
      aItem.set_read_users([email], aItem.read_users)
      aItem.set_edit_users([email], aItem.edit_users)
      aItem.save

      aItem.documents.each do |aDocument|
        aDocument.set_discover_users([email], aDocument.discover_users)
        aDocument.set_read_users([email], aDocument.read_users)
        aDocument.set_edit_users([email], aDocument.edit_users)
        aDocument.save
      end
    end
    return self.private_data_owner
  end


  #
  # Find a collection using its short_name
  #
  def Collection.find_by_short_name(short_name)
    return Collection.where(short_name: short_name).all
  end

  def setCollectionList(collectionList)
    self.collectionList = collectionList
    self.save!
  end

  def setLicence(licence)
    unless licence.nil?
      licence = Licence.find(licence.to_s) unless licence.is_a? Licence
    end
    self.licence = licence
    self.save!
  end

  def setPrivacy(status)
    self.private = status
    self.save!
  end

  def public?
    !private?
  end

  #
  # ===========================================================================
  # Support for adding licences to collections via scripts
  # ===========================================================================
  #

  #
  # Find the collection with the given short name and, as long as we found such
  # a collection, set its licence to the one supplied.
  #
  def self.assign_licence(collection_name, licence)
    # Find the collection
    array = Collection.find_by_short_name(collection_name)
    if array.empty?
      Rails.logger.error("Collection.assign_licence: cannot find a collection called #{name}")
      return
    elsif array.size > 1
      Rails.logger.error("Collection.assign_licence: multiples collections called #{name}!")
      return
    end

    collection = array[0]
    collection.set_license(licence) unless licence.nil?

    Rails.logger.info("Licence #{licence.name} assigned to Collection #{collection.flat_name}") unless licence.nil?
  end
  # End of Support for adding licences to collections via scripts
  # ---------------------------------------------------------------------------
  #
end
