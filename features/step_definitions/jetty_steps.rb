require "#{Rails.root}/lib/tasks/fedora_helper.rb"
require "#{Rails.root}/app/processors/solr_worker.rb"

SAMPLE_FOLDER = "#{Rails.root}/test/samples"

And /^I ingest "([^:]*):([^:]*)" with id "(hcsvlab:\d+)"$/ do |corpus, prefix, pid|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"

  item = Item.create(pid: pid)
  item.descMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.descMetadata.graph.statements.first.subject
  item.save!

  look_for_annotations(item, rdf_file)
  look_for_documents(item, "#{SAMPLE_FOLDER}/#{corpus}", rdf_file)
 
  item.save!

  # update solr
  Solr_Worker.new.on_message("index #{pid}")

end

And /^I have "([^:]*):([^:]*)" with id "(hcsvlab:\d+)" indexed$/ do |corpus, prefix, pid|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"

  item = Item.create(pid: pid)
  item.descMetadata.graph.load(rdf_file, :format => :ttl, :validate => true)
  item.label = item.descMetadata.graph.statements.first.subject
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
