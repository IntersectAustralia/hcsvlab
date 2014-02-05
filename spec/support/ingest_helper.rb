SAMPLE_FOLDER = "#{Rails.root}/test/samples"

#
#
#
def ingest_one(collection, identifier)
  rdf_file = "#{SAMPLE_FOLDER}/#{collection}/#{identifier}-metadata.rdf"
  response = `RAILS_ENV=test bundle exec rake fedora:ingest_one #{rdf_file}`
  pid = response[/(hcsvlab:\d+)/, 1]
  Solr_Worker.new.on_message("index #{pid}")
end
