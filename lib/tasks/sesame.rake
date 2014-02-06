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

    if (collection_dir.nil?) || (!Dir.exists?(collection_dir))
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
    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    stomp_client.publish('/queue/hcsvlab.sesame.worker', "{\"action\": \"ingest\", \"corpus_directory\":\"#{collection_dir}\"}")
  end

end
