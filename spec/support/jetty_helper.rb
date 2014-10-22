SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

#
#
#
def clear_jetty
  # clear Solr
  uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

  req = Net::HTTP::Post.new(uri)
  req.body = '<delete><query>*:*</query></delete>'

  req.content_type = "text/xml; charset=utf-8"
  req.body.force_encoding("UTF-8")
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

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
def ingest_test_collections
  qa_collections_folder = "#{Rails.root}/test/samples/test_collections"
  #puts "Ingesting collections in #{qa_collections_folder}"
  Dir.glob(qa_collections_folder.to_s + "/*").each do |aFile|
    if (Dir.exists?(aFile))
      rdf_files = Dir.glob(aFile + "/*-metadata.rdf")

      rdf_files.each do |rdf_file|
        response = `RAILS_ENV=test bundle exec rake fedora:ingest_one #{rdf_file}`
        pid = response[/(hcsvlab:\d+)/, 1]
        Solr_Worker.new.on_message("index #{pid}")
      end
    end
  end
end