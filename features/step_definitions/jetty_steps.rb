SAMPLE_FOLDER = "#{Rails.root}/test/samples"

And /^I ingest "([^:]*):([^:]*)" with id "(hcsvlab:\d+)"$/ do |corpus, prefix, pid|

  # item = create_item_from_file(rdf_file)
  # look_for_annotations(item, rdf_file)
  # look_for_documents(item, corpus_dir, rdf_file)

  item = Item.new(pid: pid)
  item.descMetadata.graph.load("#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf", :format => :ttl, :validate => true)
  item.label = item.descMetadata.graph.statements.first.subject
  item.save!
  xml = File.read("#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-solr.xml")
  # replace HCSVLAB_ID in solr xml
  xml.gsub!("HCSVLAB_ID", pid)
  xml = "<add>" + xml + "</add>"
  # create in solr with xml
  uri = URI.parse(ActiveFedora.solr_config[:url] + '/update?commit=true')

  req = Net::HTTP::Post.new(uri)
  req.body = xml

  req.content_type = "text/xml; charset=utf-8"
  req.body.force_encoding("UTF-8")
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  res.code.to_i.should eq(200)

# add documents

# add annotations
end
