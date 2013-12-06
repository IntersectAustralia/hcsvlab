require "#{Rails.root}/lib/tasks/fedora_helper.rb"
require "#{Rails.root}/app/processors/solr_worker.rb"

SAMPLE_FOLDER = "#{Rails.root}/test/samples"

And /^I ingest "([^:]*):([^:]*)"$/ do |corpus, prefix|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"
  response = `RAILS_ENV=test bundle exec rake fedora:ingest_one #{rdf_file}`
  pid = response[/(hcsvlab:\d+)/, 1]
  Solr_Worker.new.on_message("index #{pid}")
  #puts "Ingested #{rdf_file.to_s} as #{pid.to_s}"   
end

And /^I ingest "([^:]*):([^:]*)" with id "(hcsvlab:\d+)"$/ do |corpus, prefix, pid|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"

  item = Item.create(pid: pid)
  item.rdfMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.rdfMetadata.graph.statements.first.subject
  item.save!

  query = RDF::Query.new({
                             :item => {
                                 RDF::URI("http://purl.org/dc/terms/isPartOf") => :collection,
                                 RDF::URI("http://purl.org/dc/terms/identifier") => :identifier
                             }
                         })
  result = query.execute(item.rdfMetadata.graph)[0]

  collectionName = last_bit(result.collection.to_s)

  if Collection.where(short_name: collectionName).count == 0
    create_collection(collectionName, "#{SAMPLE_FOLDER}/#{corpus}")
  end

  item.collection = Collection.find_by_short_name(collectionName).first

  # Add Groups to the created item
  item.set_discover_groups(["#{collectionName}-discover"], [])
  item.set_read_groups(["#{collectionName}-read"], [])
  item.set_edit_groups(["#{collectionName}-edit"], [])
  # Add complete permission for data_owner
  data_owner = item.collection.flat_private_data_owner
  if (!data_owner.nil?)
    #puts "    Creating Item users (discover, read, edit) with #{data_owner}"
    item.set_discover_users([data_owner], [])
    item.set_read_users([data_owner], [])
    item.set_edit_users([data_owner], [])
  end

  look_for_annotations(item, rdf_file)
  look_for_documents(item, "#{SAMPLE_FOLDER}/#{corpus}")

  item.save!

  # update solr
  Solr_Worker.new.on_message("index #{pid}")

end

And /^I reindex all$/ do
    Item.all.each do |anItem|
      begin
          Solr_Worker.new.on_message("index #{anItem.pid}")
      rescue Exception=>e
        # Do nothing
      end
    end
end


And /^I ingest licences$/ do
  create_default_licences(SAMPLE_FOLDER)
end

And /^I have (\d+) licences belonging to "([^"]*)"$/ do |amount, email|
  amount = amount.to_i

  (1..amount).each { | i |
    s = sprintf("%02d", i)
    c = Collection.new
    c.uri = "www.example.com/#{s}"
    c.short_name = "Licence #{s}"
    c.private_data_owner = email
    c.privacy_status = 'false'
    c.save
  }
end

And /^I have "([^:]*):([^:]*)" with id "(hcsvlab:\d+)" indexed$/ do |corpus, prefix, pid|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"

  item = Item.create(pid: pid)
  item.rdfMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.rdfMetadata.graph.statements.first.subject

  # Add Groups to the created item
  item.set_discover_groups(["#{corpus}-discover"], [])
  item.set_read_groups(["#{corpus}-read"], [])
  item.set_edit_groups(["#{corpus}-edit"], [])

  item.save!

  xml = File.read("#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-solr.xml")
  # replace HCSVLAB_ID in solr xml
  xml.gsub!("HCSVLAB_ID", pid)
  xml = "<add>" + xml + "</add>"
  # create in solr with xml
  uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

  req = Net::HTTP::Post.new(uri)
  req.body = xml

  req.content_type = "text/xml; charset=utf-8"
  req.body.force_encoding("UTF-8")
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end
 
  res.code.to_i.should eq(200)
end


Then /^I should get the primary text for "([^:]*):([^:]*)"$/ do |corpus, prefix|
  last_response.headers['Content-Type'].should == "text/plain"
  last_response.headers['Content-Disposition'].should include("filename=\"#{prefix}-plain.txt\"")
  last_response.headers['Content-Disposition'].should include("attachment")

  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-plain.txt"
  last_response.body.should eq(File.read(rdf_file))
end

