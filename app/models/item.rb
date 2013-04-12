
class Item < ActiveFedora::Base

	has_metadata 'descMetadata', type: ActiveFedora::RdfxmlRDFDatastream

	has_many :documents, :property => :is_member_of

end