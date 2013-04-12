class Document < ActiveFedora::Base

	has_metadata 'descMetadata', type: ActiveFedora::RdfxmlRDFDatastream

	has_file_datastream name: 'file', type: ActiveFedora::Datastream

	belongs_to :item, :property => :is_member_of

end