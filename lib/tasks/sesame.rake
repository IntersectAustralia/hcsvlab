#
#
#
namespace :sesame do
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
  #
  #
  def ingest_collection(collection_dir)
    stomp_client = Stomp::Client.open "stomp://localhost:61613"
    stomp_client.publish('/queue/hcsvlab.sesame.worker', "{\"action\": \"ingest\", \"corpus_directory\":\"#{collection_dir}\"}")
  end

end
