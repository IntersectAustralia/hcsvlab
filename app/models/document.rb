include ActiveFedora::DatastreamCollections

class Document < HcsvlabActiveFedora

  # Adds useful methods form managing Item groups
  include Hydra::ModelMixins::RightsMetadata

	has_metadata 'descMetadata', type: Datastream::DocumentMetadata

  has_metadata 'rdfMetadata',  type: ActiveFedora::RdfxmlRDFDatastream

  has_datastream :name => 'content', :type => ActiveFedora::Datastream, :controlGroup => 'E'

  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

	belongs_to :item, :property => :is_member_of

  delegate :file_name, to: 'descMetadata'
  delegate :type,      to: 'descMetadata'
  delegate :mime_type, to: 'descMetadata'
  delegate :item_id,   to: 'descMetadata'

end