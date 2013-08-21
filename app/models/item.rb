include ActiveFedora::DatastreamCollections

class Item < ActiveFedora::Base

  # Adds useful methods form managing Item groups
  include Hydra::ModelMixins::RightsMetadata

  has_metadata 'descMetadata', type: Datastream::ItemMetadata

  has_file_datastream name: 'primary_text', type: ActiveFedora::Datastream

  has_datastream :name => 'annotation_set', :type => ActiveFedora::Datastream, :controlGroup => 'E', :prefix => 'annotationSet'

  has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream

  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_many :documents, :property => :is_member_of

  delegate :collection,    to: 'descMetadata'
  delegate :collection_id, to: 'descMetadata'

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
end