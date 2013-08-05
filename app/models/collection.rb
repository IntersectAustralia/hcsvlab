include ActiveFedora::DatastreamCollections

class Collection < ActiveFedora::Base

  has_metadata 'descMetadata', type: Datastream::CollectionMetadata
  has_metadata 'rdfMetadata', type: ActiveFedora::RdfxmlRDFDatastream
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata

  has_many :items, :property => :is_member_of
  belongs_to :collectionList, :property => :is_part_of

  # uri is the unique id of the collection, e.g. http://ns.ausnc.org.au/corpora/cooee
  delegate :uri,        to: 'descMetadata'

  # short_name is a nice human readable handy-type name, e.g. COOEE
  delegate :short_name, to: 'descMetadata'

  # data_owner is the e-mail address of the colection's owner.
  delegate :private_data_owner, to: 'descMetadata'


  # ---------------------------------------

  #
  # Get the data owner
  #
  def data_owner
    return User.find_by_user_key(private_data_owner)
  end

  #
  # Set the data owner
  #
  def data_owner=(user)
    case user
      when String
        self.private_data_owner = user
      when User
        self.private_data_owner = user.email
      else
        self.private_data_owner = user.to_s
    end
    return self.private_data_owner
  end


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

  def setCollectionList(collectionList)
    self.collectionList = collectionList
    self.save!
  end

  #
  # Find collection by the given user that were not assigned to any Collection List
  #
  def self.find_by_owner_email_and_unassigned(userEmail)
    collections = Collection.find(:private_data_owner => userEmail)
    return collections.select{ |c| c.collectionList.nil? }
  end

end
