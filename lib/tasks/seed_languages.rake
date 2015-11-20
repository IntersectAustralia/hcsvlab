require File.dirname(__FILE__) + '/../../db/seed_helper.rb'

desc "Populate the languages table with language codes imported from the CSV"
task :seed_languages => :environment do
  seed_languages
end