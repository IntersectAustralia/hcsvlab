def create_roles_and_permissions
  Role.delete_all
  Role.create!(:name => Role::SUPERUSER_ROLE)
  Role.create!(:name => Role::RESEARCHER_ROLE)
  Role.create!(:name => Role::DATA_OWNER_ROLE)
end

# Populates the languages table with the language names and codes from the languages CSV file
def populate_languages
  Language.delete_all
  languages = {}
  csv_file = File.join('lib', 'resources', 'languages-2015-11-09.csv')
  CSV.foreach(csv_file, :headers => true) do |csv_obj|
    languages[csv_obj['Code']] = csv_obj['Name']
  end
  languages.each do |language_code, language_name|
    Language.create!(:code => language_code, :name => language_name)
  end
end
