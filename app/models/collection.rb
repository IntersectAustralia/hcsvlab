require "#{Rails.root}/lib/solr/solr_helper.rb"

class Collection < ActiveRecord::Base

  has_many :items
  belongs_to :owner, class_name: 'User'
  belongs_to :collection_list
  belongs_to :licence

  scope :not_in_list, where(collection_list_id: nil)
  scope :only_public, where(private: false)
  scope :only_private, where(private: true)

  validates :name, presence: true

  def self.sanitise_name(name)
    name.downcase.delete(' ')
  end

  def set_licence(licence)
    self.licence = licence
    self.save!
  end

  def set_privacy(status)
    self.private = status
    self.save!
  end

  def is_public?
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
    raise "Could not find collection metadata file" unless File.exist?(self.rdf_file_path)
    RDF::Graph.load(self.rdf_file_path, :format => :ttl, :validate => true)
  end
end
