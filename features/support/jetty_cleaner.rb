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

  # clear Fedora
  Item.delete_all
  Document.delete_all
  Collection.delete_all
  CollectionList.delete_all
  Licence.delete_all

end

# Reserve first 10 for Item testing
def reserve_fedora_pids
  (1..10).each do |num|
    Item.create(pid: "hcsvlab:#{num}")
  end
end

#make sure jetty is started and clean
puts 'Ensuring jetty test instance is up...'.yellow
if Dir.glob("#{Rails.root}/tmp/pids/*jetty.pid").empty?
  puts "fedora.pid file not found. Make sure hydra-jetty is installed and the #{Rails.env} copy is installed and running".red
  exit 1
end

#make sure jetty is set up properly
output = `diff #{Rails.root}/fedora_conf/conf/test/fedora.fcfg #{Rails.root}/jetty/fedora/test/server/config/fedora.fcfg`
if output.present?
  puts "Please run rake jetty:config to set up Fedora".red
  puts output
  exit 1
end
puts 'Test jetty ready'.green

`echo '' > #{Rails.root}/log/test.log`
clear_jetty

reserve_fedora_pids

at_exit do
  clear_jetty
end

Before do |scenario|
  if scenario.instance_of?(Cucumber::Ast::Scenario)
    shouldCleanBeforeScenario = scenario.feature_tags.tags.select{|t| "@ingest_qa_collections".eql? t.name.to_s}.empty?

    if (shouldCleanBeforeScenario)
      clear_jetty
    end
  else
    clear_jetty
  end
end

Before('@ingest_qa_collections') do
  if (!$alreadyIngested)
    ingest_test_collections
    $alreadyIngested = true
  end
end