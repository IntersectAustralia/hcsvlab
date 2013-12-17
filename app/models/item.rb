include ActiveFedora::DatastreamCollections

class Item < HcsvlabActiveFedora

  # Adds useful methods form managing Item groups
  include Hydra::ModelMixins::RightsMetadata

  has_metadata 'descMetadata', type: Datastream::ItemMetadata

  has_file_datastream name: 'primary_text', type: ActiveFedora::Datastream

  has_datastream :name => 'annotation_set', :type => ActiveFedora::Datastream, :controlGroup => 'E', :prefix => 'annotationSet'

  has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream

  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_many :documents, :property => :is_member_of
  belongs_to :collection, :property => :is_member_of_collection

  delegate :handle, to: 'descMetadata'

  def flat_handle
    return handle[0]
  end

  #
  # Find an item using its collection name and id
  #
  def Item.find_by_collection_id(collection, id)
      results = Item.find_with_conditions('*:*',
                                          :fl => 'id',
                                          :fq => 'collection_tesim:' + collection.to_s +
                                                 ' AND collection_id_tesim:' + id.to_s )
      Rails.logger.warn "Multiple items for collection= #{collection} id= #{id}" if results.count > 1
      return Item.find(results[0])
  end

  #
  #
  #
  def hasPrimaryText?
    !self.primary_text.size.nil?
  end

  #
  # The list of Item fields which we should not to the user.
  #
  def self.development_only_fields
    ['id',
     'timestamp',
     'full_text',
     MetadataHelper::short_form(MetadataHelper::RDF_TYPE) + '_tesim',
     'handle',
     '_version_',
     'item_lists',
     'all_metadata',
     'discover_access_group_ssim',
     'read_access_group_ssim',
     'edit_access_group_ssim',
     'discover_access_person_ssim',
     'read_access_person_ssim',
     'edit_access_person_ssim',
     "json_metadata",
     "score"]
  end
end