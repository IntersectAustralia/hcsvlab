require 'rake'
SAMPLE_FOLDER = "#{Rails.root}/test/samples"
#
#
#
def ingest_sample(collection, identifier)

  rdf_file = "#{SAMPLE_FOLDER}/#{collection}/#{identifier}-metadata.rdf"

  rake = Rake::Application.new
  Rake.application = rake
  rake.init
  rake.load_rakefile
  rake["fedora:ingest_one"].invoke(rdf_file)

  Solr_Worker.new.on_message("index #{Item.last.id}")
end
