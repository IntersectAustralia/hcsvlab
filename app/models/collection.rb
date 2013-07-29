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
  def Item.find_by_uri(uri)
    results = Item.find_with_conditions('*:*',
                                        :fl => 'id',
                                        :fq => 'uri_tesim:' + uri.to_s )
    Rails.logger.warn "No collection with URI = #{uri}" if results.count == 0
    Rails.logger.warn "Multiple collections with URI = #{uri}" if results.count > 1
    return Item.find(results[0])
  end

  #
  # Find a collection using its short_name
  #
  def Item.find_by_short_name(short_name)
    results = Item.find_with_conditions('*:*',
                                        :fl => 'id',
                                        :fq => 'short_name_tesim:' + short_name.to_s )
    Rails.logger.warn "No collection with short name = #{short_name}" if results.count == 0
    Rails.logger.warn "Multiple collections with short name = #{short_name}" if results.count > 1
    return Item.find(results[0])
  end

end
