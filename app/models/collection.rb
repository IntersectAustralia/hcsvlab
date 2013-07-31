include ActiveFedora::DatastreamCollections

class Collection < ActiveFedora::Base

  has_metadata 'descMetadata', type: Datastream::CollectionMetadata
  has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_many :items, :property => :is_member_of

  belongs_to :user, :property => :data_owner

  # uri is the unique id of the collection, e.g. http://ns.ausnc.org.au/corpora/cooee
  delegate :uri,        to: 'descMetadata'

  # short_name is a nice human readable handy-type name, e.g. COOEE
  delegate :short_name, to: 'descMetadata'


  # ---------------------------------------


  #
  # Find a collection using its uri
  #
  def Collection.find_by_uri(uri)
    return Collection.where(uri: uri)
  end

  #
  # Find a collection using its short_name
  #
  def Collection.find_by_short_name(short_name)
    return Collection.where(short_name: short_name)
  end

end
