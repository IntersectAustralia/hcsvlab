require File.dirname(__FILE__) + '/fedora_helper.rb'

#
#
#
namespace :sesame do
  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? (SESAME_CONFIG)

  #
  # Ingest one collection metadata and annotations, given as an argument
  #
  task :ingest => :environment do

    collection_dir = ENV['collection'] unless ENV['collection'].nil?

    if collection_dir.nil? || !Dir.exists?(collection_dir)
      if collection_dir.nil?
        puts "No corpus directory specified."
      else
        puts "Collection directory #{collection_dir} does not exist."
      end
      puts "Usage: rake fedora:ingest collection=<collection folder>"
      exit 1
    end

    logger.info "rake sesame:ingest collection=#{collection_dir}"
    ingest_collection(collection_dir)
  end

  #
  # Clear and Remove each repository in Sesame
  #
  task :clear => :environment do
    # Clear Sesame
    server = RDF::Sesame::Server.new(SESAME_CONFIG["url"].to_s)
    repositories = server.repositories
    repositories.each_key do |repositoryName|
      if (!"SYSTEM".eql? repositoryName)
        server.delete(repositories[repositoryName].path)
      end
    end
  end

  #
  #
  #
  def ingest_collection(collection_dir)
    metadata_files = Dir["#{collection_dir}/**/*-metadata.rdf"]

    graph = RDF::Graph.load(metadata_files.first, :format => :ttl, :validate => true)
    query = RDF::Query.new({
                               :item => {
                                   RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection,
                                   RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                               }
                           })
    result = query.execute(graph)[0]
    collection_name = last_bit(result.collection.to_s)

    populate_triple_store(collection_dir, collection_name)

  end

end
