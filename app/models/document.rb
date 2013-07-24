include ActiveFedora::DatastreamCollections

class Document < ActiveFedora::Base

	has_metadata 'descMetadata', type: Datastream::DocumentMetadata

    has_metadata 'rdfMetadata',  type: ActiveFedora::RdfxmlRDFDatastream

    has_file_datastream :name => 'file', 
                        :type => ActiveFedora::Datastream,
                        :controlGroup => 'E'

    #has_datastream :name         => 'content', 
    #               :type         => ActiveFedora::Datastream, 
    #               :controlGroup => 'E', 
    #               :prefix       => 'content'

    has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

	belongs_to :item, :property => :is_member_of

    delegate :file_name, to: 'descMetadata'
    delegate :type,      to: 'descMetadata'
    delegate :mime_type, to: 'descMetadata'

end