SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

#
#
#
def clear_jetty
  Document.delete_all
  Item.delete_all
  Collection.delete_all
  CollectionList.delete_all

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
  data_owner = FactoryGirl.create(:user, :email => 'data_owner@intersect.org.au', :password => "Pas$w0rd", :status => 'A')
  data_owner.role = Role.find_or_create_by_name(Role::DATA_OWNER_ROLE)
  data_owner.save!
  qa_collections_folder = "#{Rails.root}/test/samples/test_collections"
  Dir.glob(qa_collections_folder.to_s + "/*").each do |aFile|
    if Dir.exists?(aFile)
      rdf_files = Dir.glob(aFile + "/*-metadata.rdf")
      require 'rake'
      rake = Rake::Application.new
      solr_worker = Solr_Worker.new
      Rake.application = rake
      rake.init
      rake.load_rakefile
      rdf_files.each do |rdf_file|
        pid = ingest_one(File.dirname(rdf_file), rdf_file)
        solr_worker.on_message("index #{pid}")
      end
    end
  end
end
