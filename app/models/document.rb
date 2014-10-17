class Document < ActiveRecord::Base

  # Adds useful methods form managing Item groups
  include Hydra::ModelMixins::RightsMetadata
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_metadata 'descMetadata', type: Datastream::DocumentMetadata

  has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream # => link to rdf file

  has_datastream :name => 'content', :type => ActiveFedora::Datastream, :controlGroup => 'E' # => link to file

  belongs_to :item

  delegate :file_name, to: 'descMetadata'
  delegate :type, to: 'descMetadata'
  delegate :mime_type, to: 'descMetadata'
  delegate :item_id, to: 'descMetadata'

end