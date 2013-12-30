require 'json'
require "#{Rails.root}/lib/rdf-sesame/hcsvlab_repository.rb"
require "#{Rails.root}/lib/rdf-sesame/hcsvlab_server.rb"

#
# Sesame worker is responsible for ingesting RDF metadata and annotations into sesame triple store
#
class Sesame_Worker < ApplicationProcessor

  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless const_defined?(:SESAME_CONFIG)

  subscribes_to :sesame_worker

  #
  #
  #
  def on_message(message)

    debug("Sesame_worker", "Receive message #{message}")

    jsonMessage = JSON.parse(message)

    case jsonMessage['action']
      when 'ingest'
        ingest_rdf_files(jsonMessage['corpus_directory'])
    end
  end

  private

  #
  # Given a directory, it will ingest every *-metadata.rdf and *-ann.rdf file into the
  # corresponding repository. If the repository does not exists, this will create it.
  #
  def ingest_rdf_files(corpus_directory)
    debug("Sesame_worker", "Start ingesting metadata and annotations in #{corpus_directory}")
    metadataFiles = Dir["#{corpus_directory}/**/*-metadata.rdf"]

    graph = RDF::Graph.load(metadataFiles.first, :format => :ttl, :validate => true)
    query = RDF::Query.new({
                               :item => {
                                   RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection,
                                   RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                               }
                           })
    result = query.execute(graph)[0]
    collection_name = last_bit(result.collection.to_s)
    # small hack to handle austalk for the time being, can be fixed up
    # when we look at getting some form of data uniformity
    if query.execute(graph).any? {|r| r.collection == "http://ns.austalk.edu.au/corpus"}
      collection_name = "austalk"
    end

    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)

    # First we will create the repository for the collection, in case it does not exists
    server.create_repository(RDF::Sesame::HcsvlabServer::NATIVE_STORE_TYPE, collection_name, "Metadata and Annotations for #{collection_name} collection")

    # Create a instance of the repository where we are going to store the metadata
    repository = server.repository(collection_name)

    # Now will store every RDF file
    repository.insert_from_rdf_files(metadataFiles)

    annotationsFiles = Dir["#{corpus_directory}/**/*-ann.rdf"]
    # Now will store every RDF file
    repository.insert_from_rdf_files(annotationsFiles)

    #insert_access_control_info(collection_name, repository)

    debug("Sesame_worker", "Finished ingesting metadata and annotations in #{corpus_directory}")

  end

  #
  # This method will try to get all the items in a collection and add
  # some triples related with each item in order to apply access control
  # to them.
  #
  def insert_access_control_info(collection_name, repository)
    sparqlQuery = """
      PREFIX ausnc: <http://ns.ausnc.org.au/schemas/ausnc_md_model/>

      SELECT *
      WHERE {
        ?item_id ?p ausnc:AusNCObject .
      }
    """

    results = repository.sparql_query(sparqlQuery)
    statements = []
    results.each do |rdfItem|
      item_id = rdfItem['item_id']


      #[RDF::Resource]          subject
      #   @param  [RDF::URI]               predicate
      #   @param  [RDF::Term]              object
      subject = RDF::Resource.new(item_id)
      predicate = RDF::URI.new("http://ns.ausnc.org.au/schemas/ausnc_md_model/auth")
      object = "#{collection_name}-read"

      statement = RDF::Statement.new(subject, predicate, object)

      statements << statement
    end

    debug("Sesame worker", "Inserting #{statements.size} access control statements")

    statements.in_groups_of(1000, false).each do |statementsGroups|
      repository.insert_statements(statementsGroups)
    end
  end

  #
  # Extract the last part of a path/URI/slash-separated-list-of-things
  #
  def last_bit(uri)
    str = uri.to_s                # just in case it is not a String object
    return str if str.match(/\s/) # If there are spaces, then it's not a path(?)
    return str.split('/')[-1]
  end

end
