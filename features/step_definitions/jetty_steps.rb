require "#{Rails.root}/lib/tasks/fedora_helper.rb"
require "#{Rails.root}/app/processors/solr_worker.rb"

SAMPLE_FOLDER = "#{Rails.root}/test/samples"

And /^I ingest "([^:]*):([^:]*)"$/ do |corpus, prefix|
  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-metadata.rdf"
  corpus_dir = "#{SAMPLE_FOLDER}/#{corpus}"

  pid = ingest_one(corpus_dir, rdf_file)

  # # update solr
  Solr_Worker.new.on_message("index #{pid}")
end

And /^I reindex all$/ do
  Item.all.each do |anItem|
    begin
      Solr_Worker.new.on_message("index #{anItem.id}")
    rescue Exception => e
      # Do nothing
    end
  end
end


And /^I ingest licences$/ do
  create_default_licences(SAMPLE_FOLDER)
end

And /^I have (\d+) licences belonging to "([^"]*)"$/ do |amount, email|
  amount = amount.to_i

  (1..amount).each { |i|
    s = sprintf("%02d", i)
    c = Collection.new
    c.uri = "www.example.com/#{s}"
    c.name = "Licence #{s}"
    c.owner = User.find_by_email(email)
    c.private = false
    c.save
  }
end

Then /^I should get the primary text for "([^:]*):([^:]*)"$/ do |corpus, prefix|
  last_response.headers['Content-Type'].should == "text/plain"
  last_response.headers['Content-Disposition'].should include("filename=\"#{prefix}-plain.txt\"")
  last_response.headers['Content-Disposition'].should include("attachment")

  rdf_file = "#{SAMPLE_FOLDER}/#{corpus}/#{prefix}-plain.txt"
  last_response.body.should eq(File.read(rdf_file))
end

