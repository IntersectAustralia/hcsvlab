include ActiveFedora::DatastreamCollections

class Item < ActiveFedora::Base

    has_metadata 'descMetadata', type: Datastream::ItemMetadata

    has_file_datastream name: 'primary_text', type: ActiveFedora::Datastream

  	has_datastream :name => 'annotation_set', :type => ActiveFedora::Datastream, :controlGroup => 'E', :prefix => 'annotationSet'

  	has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream

    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

    has_many :documents, :property => :is_member_of

    delegate :collection,    to: 'descMetadata'
    delegate :collection_id, to: 'descMetadata'

end