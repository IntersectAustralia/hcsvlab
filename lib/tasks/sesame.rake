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

    dir = ENV['dir'] unless ENV['dir'].nil?
    corpus = ENV['corpus'] unless ENV['corpus'].nil?
    glob = ENV['glob'] unless ENV['glob'].nil?

    if dir.nil? || !Dir.exists?(dir) ||  corpus.nil? ||  glob.nil?
        if dir.nil?
        puts "No directory specified."
      else
        puts "Directory #{dir} does not exist."
      end
      puts "Usage: rake sesame:ingest dir=<dir> corpus=<corpus> glob=<glob>"
      exit 1
    end

    logger.info "rake sesame:ingest dir=#{dir} corpus=#{corpus} glob=#{glob}"
    populate_triple_store(dir, corpus, glob)
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


end
