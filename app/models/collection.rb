require "#{Rails.root}/lib/solr/solr_helper.rb"

class Collection < ActiveRecord::Base
  include SolrHelper

  has_many :items
  belongs_to :owner, class_name: 'User'
  belongs_to :collection_list
  belongs_to :licence

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
    array = Collection.where(name: collection_name)
    if array.empty?
      Rails.logger.error("Collection.assign_licence: cannot find a collection called #{name}")
      return
    elsif array.size > 1
      Rails.logger.error("Collection.assign_licence: multiples collections called #{name}!")
      return
    end

    collection = array[0]
    collection.set_licence(licence) unless licence.nil?

    Rails.logger.info("Licence #{licence.name} assigned to Collection #{collection.name}") unless licence.nil?
  end
  # End of Support for adding licences to collections via scripts
  # ---------------------------------------------------------------------------
  #

  def rdf_graph
    RDF::Graph.load(self.rdf_file_path, :format => :ttl, :validate => true)
  end
end
