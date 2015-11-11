#Todo: auto start rake task and make it safe/non-repeatable
namespace :language_code_csv do
  desc "Populates the languages db table with the language codes and names from the language csv file"
  task :create_languages => :environment do
    languages = {}
    csv_file = File.join('lib', 'tasks', 'resources', 'languages-2015-11-09.csv')
    CSV.foreach(csv_file, :headers => true) do |csv_obj|
      languages[csv_obj['Code']] = csv_obj['Name']
    end
    languages.each do |language_code, language_name|
      Language.create!(:code => language_code, :name => language_name)
    end
  end
end