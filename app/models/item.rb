
class Item < ActiveFedora::Base

    has_file_datastream name: 'primary_text', type: ActiveFedora::Datastream

    has_metadata 'descMetadata', type: ActiveFedora::RdfxmlRDFDatastream

	has_many :documents, :property => :is_member_of

end